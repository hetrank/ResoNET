# ResoNET

ResoNET is an accessibility tool for deaf users that continuously listens to environmental audio and runs on-device sound classification using a custom YAMNet-style TensorFlow Lite model.

## Setup

1. Put your model and labels into:
	- `assets/model.tflite`
	- `assets/labels.txt`

2. Install dependencies:
	- `flutter pub get`

3. Run on a physical device (recommended for microphone + vibration):
	- `flutter run`

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
