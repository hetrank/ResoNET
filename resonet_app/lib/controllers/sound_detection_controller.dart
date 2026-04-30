import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import '../models/enrolled_sound.dart';
import '../models/sound_detection.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/tflite_service.dart';

class SoundDetectionController extends ChangeNotifier {
  SoundDetectionController({
    required AudioService audioService,
    required StorageService storageService,
    required TfliteService tfliteService,
    this.similarityThreshold = 0.70,
    bool autoStart = true,
  })  : _audioService = audioService,
        _storageService = storageService,
        _tfliteService = tfliteService {
    if (autoStart) {
      unawaited(_init());
    }
  }

  final AudioService _audioService;
  final StorageService _storageService;
  final TfliteService _tfliteService;
  final double similarityThreshold;

  List<EnrolledSound> _enrolledSounds = const <EnrolledSound>[];
  List<EnrolledSound> get enrolledSounds => _enrolledSounds;

  StreamSubscription<Float32List>? _audioSubscription;
  bool _processing = false;
  bool _inferencePaused = false;

  Float32List? _audioWindow;

  bool _isListening = false;
  bool get isListening => _isListening;

  String _displayText = 'Listening...';
  String get displayText => _displayText;

  double _confidence = 0.0;
  double get confidence => _confidence;

  double _level = 0.0;
  double get level => _level;

  String? _error;
  String? get error => _error;

  DateTime _lastVibration = DateTime.fromMillisecondsSinceEpoch(0);
  bool? _hasVibrator;

  Future<void> _init() async {
    try {
      await _tfliteService.load();
      _audioWindow = Float32List(_tfliteService.expectedInputSamples);
      _enrolledSounds = await _storageService.loadEnrolledSounds();
      _hasVibrator = await Vibration.hasVibrator();
      await start();
    } catch (e) {
      _error = e.toString();
      _displayText = 'Microphone or model error';
      notifyListeners();
    }
  }

  Future<void> reloadEnrolledSounds() async {
    _enrolledSounds = await _storageService.loadEnrolledSounds();
    notifyListeners();
  }

  Future<void> start() async {
    if (_isListening) {
      return;
    }

    _error = null;
    _displayText = 'Listening...';
    notifyListeners();

    await _audioService.start();
    _isListening = true;
    _inferencePaused = false;

    _audioSubscription = _audioService.chunks.listen(
      _onAudioChunk,
      onError: (Object e) {
        _error = e.toString();
        _displayText = 'Audio stream error';
        notifyListeners();
      },
    );

    notifyListeners();
  }

  Future<void> pauseInference() async {
    if (!_isListening || _inferencePaused) {
      return;
    }

    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _inferencePaused = true;
    _processing = false;
    notifyListeners();
  }

  Future<void> resumeInference() async {
    if (!_isListening || !_inferencePaused) {
      return;
    }

    _audioSubscription = _audioService.chunks.listen(
      _onAudioChunk,
      onError: (Object e) {
        _error = e.toString();
        _displayText = 'Audio stream error';
        notifyListeners();
      },
    );
    _inferencePaused = false;
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_isListening) {
      return;
    }

    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _audioService.stop();

    _isListening = false;
    _inferencePaused = false;
    _displayText = 'Stopped';
    _confidence = 0.0;
    _level = 0.0;
    notifyListeners();
  }

  void _onAudioChunk(Float32List chunk) {
    _level = _rms(chunk);
    notifyListeners();

    final window = _audioWindow;
    if (window != null) {
      _appendToWindow(window, chunk);
    }

    if (_processing) {
      return;
    }

    _processing = true;
    scheduleMicrotask(() {
      try {
        if (_enrolledSounds.isEmpty) {
          _displayText = 'Listening...';
          _confidence = 0.0;
          return;
        }

        final audioForInference = _audioWindow ?? chunk;
        final SoundDetection? best = _tfliteService.bestMatch(audioForInference, _enrolledSounds);
        final bestScore = best?.confidence ?? 0.0;
        _confidence = bestScore;

        if (best != null && bestScore >= similarityThreshold) {
          _displayText = best.label.toUpperCase();
          _maybeVibrate();
        } else {
          _displayText = 'Listening...';
        }
      } catch (e) {
        _error = e.toString();
        _displayText = 'Inference error';
      } finally {
        _processing = false;
        notifyListeners();
      }
    });
  }

  void _appendToWindow(Float32List window, Float32List chunk) {
    if (chunk.isEmpty) {
      return;
    }

    final windowLen = window.length;
    if (chunk.length >= windowLen) {
      final start = chunk.length - windowLen;
      window.setRange(0, windowLen, chunk, start);
      return;
    }

    final shift = chunk.length;
    window.setRange(0, windowLen - shift, window, shift);
    window.setRange(windowLen - shift, windowLen, chunk);
  }

  double _rms(Float32List data) {
    if (data.isEmpty) {
      return 0.0;
    }

    var sumSq = 0.0;
    for (final v in data) {
      sumSq += v * v;
    }

    final rms = math.sqrt(sumSq / data.length);
    return rms.clamp(0.0, 1.0);
  }

  Future<void> _maybeVibrate() async {
    final now = DateTime.now();
    if (now.difference(_lastVibration).inMilliseconds < 900) {
      return;
    }
    _lastVibration = now;

    final hasVibrator = _hasVibrator ?? (await Vibration.hasVibrator()) == true;
    if (!hasVibrator) {
      return;
    }

    await Vibration.vibrate(duration: 200);
  }

  @override
  void dispose() {
    unawaited(_audioSubscription?.cancel());
    _tfliteService.dispose();
    unawaited(_audioService.dispose());
    super.dispose();
  }
}
