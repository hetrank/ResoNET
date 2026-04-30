import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/enrolled_sound.dart';
import '../models/sound_detection.dart';

class TfliteService {
  Interpreter? _interpreter;

  int _expectedInputSamples = 16000;
  int _expectedEmbeddingSize = 128;
  int _inputRank = 1;
  int _outputRank = 1;

  bool get isLoaded => _interpreter != null;
  int get expectedInputSamples => _expectedInputSamples;

  Future<void> load() async {
    if (_interpreter != null) {
      return;
    }

    final options = InterpreterOptions()..threads = 2;
    final (assetKey, modelBytes) = await _loadModelBytes();
    try {
      _interpreter = Interpreter.fromBuffer(modelBytes, options: options);
    } on ArgumentError catch (e) {
      throw StateError(
        'Unable to create TFLite interpreter from "$assetKey" '
        '(model size: ${modelBytes.length} bytes). '
        'This usually means the .tflite model is corrupt or contains unsupported/custom ops '
        '(e.g., Select TF Ops/Flex, tf.signal ops, custom layers). '
        'Original error: $e',
      );
    } catch (e) {
      throw StateError(
        'Unable to create TFLite interpreter from "$assetKey" '
        '(model size: ${modelBytes.length} bytes). '
        'Original error: $e',
      );
    }

    final inputTensor = _interpreter!.getInputTensor(0);
    final inputShape = inputTensor.shape;
    _inputRank = inputShape.length;
    if (inputShape.isNotEmpty) {
      _expectedInputSamples = inputShape.last;
    }

    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    _outputRank = outputShape.length;
    if (outputShape.isNotEmpty) {
      _expectedEmbeddingSize = outputShape.last;
    }

    debugPrint('TFLite model loaded — input shape: $inputShape (rank $_inputRank), '
        'output shape: $outputShape (rank $_outputRank), '
        'expectedSamples: $_expectedInputSamples, embeddingSize: $_expectedEmbeddingSize');
  }

  Float32List getEmbedding(Float32List audioChunk) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('TFLite interpreter not loaded');
    }

    final input = _fitToInput(audioChunk, _expectedInputSamples);
    final output = Float32List(_expectedEmbeddingSize);

    // Always pass input/output with the correct shape the model expects.
    // For models with a batch dimension (rank >= 2), we must wrap in a list
    // so that tf.map_fn inside YAMNet iterates once over the full waveform
    // instead of iterating over each scalar sample.
    final inputObj = _inputObject(input);
    final outputObj = _outputObject(output);

    interpreter.run(inputObj, outputObj);

    // If the output was wrapped for rank >= 2, extract the inner buffer.
    if (_outputRank >= 2) {
      final inner = (outputObj as List)[0];
      if (inner is Float32List) {
        return _l2Normalize(inner);
      }
      // If tflite_flutter returned List<double> instead of Float32List
      final result = Float32List(_expectedEmbeddingSize);
      if (inner is List) {
        for (var i = 0; i < result.length && i < inner.length; i++) {
          result[i] = (inner[i] as num).toDouble();
        }
      }
      return _l2Normalize(result);
    }

    return _l2Normalize(output);
  }

  Future<(String, Uint8List)> _loadModelBytes() async {
    const candidates = <String>[
      'assets/model.tflite',
      'model.tflite',
    ];

    Object? lastError;
    for (final key in candidates) {
      try {
        final data = await rootBundle.load(key);
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        if (bytes.isEmpty) {
          lastError = StateError('Asset "$key" loaded empty bytes');
          continue;
        }
        return (key, bytes);
      } catch (e) {
        lastError = e;
      }
    }

    throw StateError('Failed to load TFLite model asset. Last error: $lastError');
  }

  SoundDetection? identifySound(
    Float32List audioChunk,
    List<EnrolledSound> enrolledSounds, {
    double threshold = 0.85,
  }) {
    final best = bestMatch(audioChunk, enrolledSounds);
    if (best == null || best.confidence < threshold) {
      return null;
    }
    return best;
  }

  SoundDetection? bestMatch(Float32List audioChunk, List<EnrolledSound> enrolledSounds) {
    if (enrolledSounds.isEmpty) {
      return null;
    }

    final embedding = getEmbedding(audioChunk);

    EnrolledSound? best;
    var bestScore = -1.0;
    for (final sound in enrolledSounds) {
      final enrolled = _l2Normalize(
        Float32List.fromList(sound.embedding.map((e) => e.toDouble()).toList(growable: false)),
      );
      final s = _dot(embedding, enrolled);
      if (s > bestScore) {
        bestScore = s;
        best = sound;
      }
    }

    if (best == null) {
      return null;
    }

    return SoundDetection(label: best.name, confidence: bestScore);
  }

  Float32List _fitToInput(Float32List input, int expectedSamples) {
    if (input.length == expectedSamples) {
      return input;
    }

    final out = Float32List(expectedSamples);
    final n = math.min(expectedSamples, input.length);
    out.setRange(0, n, input);
    return out;
  }

  Object _inputObject(Float32List input) {
    if (_inputRank <= 1) {
      return input;
    }

    if (_inputRank == 2) {
      // Wrap with batch dimension: [1, N] — keep as Float32List for efficient native mapping.
      return <Float32List>[input];
    }

    if (_inputRank == 3) {
      final asList = input.toList(growable: false);
      final withChannel = asList.map((v) => <double>[v]).toList(growable: false);
      return <List<List<double>>>[withChannel];
    }

    throw UnsupportedError('Unsupported input rank: $_inputRank');
  }

  Object _outputObject(Object output) {
    if (_outputRank <= 1) {
      return output;
    }

    if (_outputRank == 2) {
      return <Object>[output];
    }

    throw UnsupportedError('Unsupported output rank: $_outputRank');
  }

  Float32List _l2Normalize(Float32List v) {
    var sumSq = 0.0;
    for (final x in v) {
      sumSq += x * x;
    }
    if (sumSq <= 0) {
      return v;
    }

    final scale = 1.0 / math.sqrt(sumSq);
    final out = Float32List(v.length);
    for (var i = 0; i < v.length; i++) {
      out[i] = (v[i] * scale).toDouble();
    }
    return out;
  }

  double _dot(Float32List a, Float32List b) {
    final n = math.min(a.length, b.length);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
