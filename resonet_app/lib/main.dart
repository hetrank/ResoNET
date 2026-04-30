import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/sound_detection_controller.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'services/tflite_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ResoNETApp());
}

class ResoNETApp extends StatelessWidget {
  const ResoNETApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioService>(create: (_) => AudioService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<TfliteService>(create: (_) => TfliteService()),
        ChangeNotifierProvider<SoundDetectionController>(
          create: (context) => SoundDetectionController(
            audioService: context.read<AudioService>(),
            storageService: context.read<StorageService>(),
            tfliteService: context.read<TfliteService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ResoNET',
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
