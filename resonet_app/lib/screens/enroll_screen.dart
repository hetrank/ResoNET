import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sound_detection_controller.dart';
import '../models/enrolled_sound.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/tflite_service.dart';

class EnrollScreen extends StatefulWidget {
  const EnrollScreen({super.key});

  @override
  State<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends State<EnrollScreen> {
  final TextEditingController _nameController = TextEditingController();

  bool _busy = false;
  String? _error;
  Float32List? _embedding;
  bool _paused = false;
  SoundDetectionController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= context.read<SoundDetectionController>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _controller?.pauseInference();
        if (mounted) {
          setState(() {
            _paused = true;
          });
        }
      } catch (_) {
        // Best-effort pause.
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    if (_paused) {
      // Best-effort resume.
      _controller?.resumeInference();
    }
    super.dispose();
  }

  Future<void> _record() async {
    if (_busy) return;

    final tflite = context.read<TfliteService>();
    final audioService = context.read<AudioService>();

    setState(() {
      _busy = true;
      _error = null;
      _embedding = null;
    });

    try {
      await tflite.load();

      final windowLen = tflite.expectedInputSamples;
      final window = Float32List(windowLen);

      await audioService.start();

      final iterator = StreamIterator<Float32List>(audioService.chunks);
      try {
        final chunkLen = AudioService.samplesPerChunk;
        final chunksNeeded = (windowLen / chunkLen).ceil();
        for (var i = 0; i < chunksNeeded; i++) {
          final hasNext = await iterator.moveNext();
          if (!hasNext) {
            throw StateError('Audio stream ended unexpectedly');
          }
          _appendToWindow(window, iterator.current);
        }
      } finally {
        await iterator.cancel();
      }

      final embedding = tflite.getEmbedding(window);

      if (mounted) {
        setState(() {
          _embedding = embedding;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
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

  Future<void> _save() async {
    if (_busy) return;

    final storage = context.read<StorageService>();
    final navigator = Navigator.of(context);

    final name = _nameController.text.trim();
    final embedding = _embedding;
    if (name.isEmpty || embedding == null) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final enrolled = EnrolledSound(
        name: name,
        embedding: embedding.map((e) => e.toDouble()).toList(growable: false),
      );

      await storage.addOrReplace(enrolled);
      await _controller?.reloadEnrolledSounds();

      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty && _embedding != null && !_busy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Sound'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Sound name',
                hintText: 'e.g., Door knock',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _record,
              child: Text(_busy ? 'Working…' : 'Record sample'),
            ),
            const SizedBox(height: 12),
            Text(
              _embedding == null
                  ? 'No sample recorded yet.'
                  : 'Sample captured. Ready to save.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: canSave ? _save : null,
              child: const Text('Save Enrollment'),
            ),
          ],
        ),
      ),
    );
  }
}
