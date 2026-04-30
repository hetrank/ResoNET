import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  static const int sampleRateHz = 16000;
  static const int numChannels = 1;
  static const int samplesPerChunk = sampleRateHz; // 1 second

  AudioService({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final StreamController<Float32List> _chunkController = StreamController.broadcast();

  StreamSubscription<Uint8List>? _pcmSubscription;

  Completer<Float32List>? _captureCompleter;
  bool _suspendBroadcast = false;

  Uint8List? _leftoverByte;
  Float32List _currentChunk = Float32List(samplesPerChunk);
  int _currentChunkIndex = 0;

  Stream<Float32List> get chunks => _chunkController.stream;

  Future<Float32List> captureNextChunk({Duration timeout = const Duration(seconds: 3)}) async {
    if (_captureCompleter != null) {
      throw StateError('Audio capture already in progress');
    }

    await start();

    _suspendBroadcast = true;
    _currentChunk = Float32List(samplesPerChunk);
    _currentChunkIndex = 0;
    _leftoverByte = null;

    final completer = Completer<Float32List>();
    _captureCompleter = completer;

    Timer? timer;
    if (timeout > Duration.zero) {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Timed out waiting for audio chunk'));
        }
      });
    }

    try {
      return await completer.future;
    } finally {
      timer?.cancel();
      _captureCompleter = null;
      _suspendBroadcast = false;
    }
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start() async {
    final granted = await requestMicrophonePermission();
    if (!granted) {
      throw StateError('Microphone permission not granted');
    }

    final isAlreadyRecording = await _recorder.isRecording();
    if (isAlreadyRecording) {
      return;
    }

    final config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRateHz,
      numChannels: numChannels,
    );

    final Stream<Uint8List> stream = await _recorder.startStream(config);
    _pcmSubscription = stream.listen(
      _onPcmBytes,
      onError: (Object error, StackTrace stackTrace) {
        if (!_chunkController.isClosed) {
          _chunkController.addError(error, stackTrace);
        }
      },
    );
  }

  void _onPcmBytes(Uint8List bytes) {
    int offset = 0;

    if (_leftoverByte != null && bytes.isNotEmpty) {
      final combined = Uint8List(2);
      combined[0] = _leftoverByte![0];
      combined[1] = bytes[0];
      _leftoverByte = null;
      offset = 1;
      _pushSample(_int16LittleEndian(combined, 0));
    }

    for (; offset + 1 < bytes.length; offset += 2) {
      _pushSample(_int16LittleEndian(bytes, offset));
    }

    if (offset < bytes.length) {
      _leftoverByte = Uint8List(1)..[0] = bytes[offset];
    }
  }

  int _int16LittleEndian(Uint8List bytes, int offset) {
    final lo = bytes[offset];
    final hi = bytes[offset + 1];
    final value = (hi << 8) | lo;
    return value >= 0x8000 ? value - 0x10000 : value;
  }

  void _pushSample(int pcm16) {
    final normalized = (pcm16 / 32768.0).clamp(-1.0, 1.0).toDouble();
    _currentChunk[_currentChunkIndex] = normalized;
    _currentChunkIndex++;

    if (_currentChunkIndex >= samplesPerChunk) {
      final completed = _currentChunk;

      final captureCompleter = _captureCompleter;
      if (captureCompleter != null && !captureCompleter.isCompleted) {
        captureCompleter.complete(completed);
      } else if (!_suspendBroadcast) {
        _chunkController.add(completed);
      }

      _currentChunk = Float32List(samplesPerChunk);
      _currentChunkIndex = 0;
    }
  }

  Future<void> stop() async {
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _leftoverByte = null;
    final captureCompleter = _captureCompleter;
    if (captureCompleter != null && !captureCompleter.isCompleted) {
      captureCompleter.completeError(StateError('Audio recording stopped'));
    }
    _captureCompleter = null;
    _suspendBroadcast = false;
    _currentChunk = Float32List(samplesPerChunk);
    _currentChunkIndex = 0;
  }

  Future<void> dispose() async {
    await stop();
    await _chunkController.close();
    await _recorder.dispose();
  }
}
