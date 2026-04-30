// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:resonet_app/controllers/sound_detection_controller.dart';
import 'package:resonet_app/screens/home_screen.dart';
import 'package:resonet_app/services/audio_service.dart';
import 'package:resonet_app/services/storage_service.dart';
import 'package:resonet_app/services/tflite_service.dart';

void main() {
  testWidgets('Shows listening state by default', (WidgetTester tester) async {
    final audioService = AudioService();
    final storageService = StorageService();
    final tfliteService = TfliteService();
    final controller = SoundDetectionController(
      audioService: audioService,
      storageService: storageService,
      tfliteService: tfliteService,
      autoStart: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AudioService>.value(value: audioService),
          Provider<StorageService>.value(value: storageService),
          Provider<TfliteService>.value(value: tfliteService),
          ChangeNotifierProvider<SoundDetectionController>.value(value: controller),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('Listening...'), findsOneWidget);
  });
}
