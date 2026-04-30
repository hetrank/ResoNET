import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sound_detection_controller.dart';
import 'enroll_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EnrollScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Consumer<SoundDetectionController>(
          builder: (context, controller, _) {
            final display = controller.displayText;
            final confidence = controller.confidence;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ListeningIndicator(
                            animation: _controller,
                            level: controller.level,
                            isActive: controller.isListening,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            display,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            controller.error != null
                                ? controller.error!
                                : (controller.enrolledSounds.isEmpty
                                    ? 'Tap + to enroll a sound'
                                    : 'Similarity ${confidence.toStringAsFixed(4)}'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(191),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ListeningIndicator extends StatelessWidget {
  const _ListeningIndicator({
    required this.animation,
    required this.level,
    required this.isActive,
  });

  final Animation<double> animation;
  final double level;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final pulse = isActive ? (0.85 + 0.15 * t) : 0.75;
        final amplitude = (level.clamp(0.0, 1.0)) * 0.9 + 0.1;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: pulse,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(166), width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isActive ? color : color.withAlpha(102),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _WaveBars(
              color: color,
              animationValue: t,
              amplitude: isActive ? amplitude : 0.12,
            ),
          ],
        );
      },
    );
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars({
    required this.color,
    required this.animationValue,
    required this.amplitude,
  });

  final Color color;
  final double animationValue;
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    const barCount = 12;
    final bars = List<Widget>.generate(barCount, (i) {
      final phase = (i / barCount) * math.pi * 2;
      final wobble = 0.55 + 0.45 * math.sin(phase + animationValue * math.pi * 2);
      final height = 10 + 44 * amplitude * wobble;

      return Container(
        width: 6,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(217),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars,
    );
  }
}
