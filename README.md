# ResoNET - Sound Classification for Deaf Accessibility

## Objective and Description
ResoNET is a digital accessibility solution powered by deep learning models that provides real-time sound classification and environmental audio awareness for deaf and hard-of-hearing individuals. The application continuously listens to environmental audio and processes sounds through custom-trained neural networks to provide haptic feedback and visual notifications of important sounds.

## Features
- Real-time environmental sound classification using deep learning
- Multiple model architectures (CNN, RNN, YAMNet)
- On-device inference with TensorFlow Lite
- Haptic feedback for sound alerts
- Flutter-based mobile application
- Support for diverse audio environments

## Installation and Setup

### Prerequisites
- Python 3.8 or higher
- TensorFlow 2.x
- Flutter (for the mobile app)
- pip package manager

### For Machine Learning Models

1. Clone the repository:
```bash
git clone https://github.com/hetrank/ResoNET.git
cd ResoNET
```

2. Install Python dependencies:
```bash
pip install tensorflow tensorflow_hub librosa numpy pandas scikit-learn matplotlib jupyter
```

3. For Google Colab notebooks (recommended for training):
- Open any .ipynb file (e.g., Audio_CNN_model_ResoNET.ipynb) in Google Colab
- Runtime should be set to GPU for faster training
- Follow the notebook cells sequentially

### For Mobile Application (resonet_app)

1. Navigate to the app directory:
```bash
cd resonet_app
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Prepare the model files:
   - Place your trained TensorFlow Lite model at: `assets/model.tflite`
   - Place the labels file at: `assets/labels.txt`

4. Run on a physical device (recommended for microphone and vibration access):
```bash
flutter run
```

## Running the Application

### Training Models

The repository includes three model implementations:

1. **Audio CNN Model** (Audio_CNN_model_ResoNET.ipynb)
   - Convolutional Neural Network for sound classification
   - Best for: General audio classification
   - Run in Google Colab with GPU acceleration

2. **Audio RNN Model** (Audio_RNN_model_ResoNET.ipynb)
   - Recurrent Neural Network with LSTM layers
   - Best for: Sequential audio pattern recognition
   - Captures temporal dependencies in audio

3. **YAMNet Model** (Audio_YAMNet_model_ResoNET.ipynb)
   - Transfer learning with Google's YAMNet architecture
   - Best for: Pre-trained general-purpose sound classification
   - Fine-tuned for specific use cases

4. **Raw Waveform Baseline** (Raw_Waveform_Baseline.ipynb)
   - Baseline model using raw waveform data
   - Reference implementation for comparison

5. **Metric Learning** (ResoNET_Metric_Learning.ipynb)
   - Advanced approach using similarity metrics
   - For improved clustering and classification

### Steps to Run Training:
1. Open the desired notebook in Google Colab
2. Update the data paths to your dataset location
3. Adjust hyperparameters as needed
4. Run all cells sequentially
5. Export the trained model as TensorFlow Lite format

### Running the Flutter App:
1. Ensure model files are in the assets directory
2. Connect a physical Android or iOS device
3. Execute: `flutter run`
4. Grant microphone and vibration permissions when prompted

## Usage Guide

### As a User
- The app continuously monitors ambient sounds
- When a sound is detected and classified, haptic feedback alerts the user
- Visual notifications display the identified sound category
- No internet connection required for inference

### For Developers

**Model Training:**
1. Prepare your dataset with labeled audio files
2. Use the provided notebooks to preprocess and train
3. Export models to TensorFlow Lite format
4. Integrate into the Flutter application

**Data Preparation:**
- Audio files should be in WAV or MP3 format
- Recommended sample rate: 16kHz or 44.1kHz
- Duration: Typically 1-5 seconds per sample

**Dataset Structure:**
```
Data/
├── class1/
│   ├── sound1.wav
│   ├── sound2.wav
│   └── ...
├── class2/
│   ├── sound1.wav
│   └── ...
└── ...
```

## Repository Structure

```
ResoNET/
├── Audio_CNN_model_ResoNET.ipynb          # CNN model notebook
├── Audio_RNN_model_ResoNET.ipynb          # RNN model notebook
├── Audio_YAMNet_model_ResoNET.ipynb       # YAMNet transfer learning
├── Raw_Waveform_Baseline.ipynb            # Baseline implementation
├── ResoNET_Metric_Learning.ipynb          # Metric learning approach
├── Data/                                   # Dataset directory
├── Prototype/                              # Prototype implementations
├── resonet_app/                            # Flutter mobile application
│   ├── lib/                                # App source code
│   ├── assets/                             # Model and labels
│   ├── pubspec.yaml                        # Flutter dependencies
│   └── ...
└── README.md                               # This file
```

## Model Specifications

### Audio CNN Model
- Input: 13-D MFCC features or spectrogram
- Architecture: 2-3 convolutional layers with pooling
- Output: Sound class predictions with probabilities
- Accuracy: ~85-92% on test data

### Audio RNN Model
- Input: Sequential MFCC frames
- Architecture: LSTM layers with dropout
- Output: Temporal sequence classification
- Best for continuous monitoring

### YAMNet Model
- Pre-trained on AudioSet dataset
- ~480 different sound classes
- Transfer learning fine-tuning available
- Fast inference (~10-50ms per sample)

## Dependencies

**Python Packages:**
- tensorflow >= 2.0
- tensorflow_hub >= 0.12
- librosa >= 0.9
- numpy >= 1.19
- pandas >= 1.0
- scikit-learn >= 0.23
- matplotlib >= 3.3

**Flutter Packages:**
- tflite_flutter
- permission_handler
- vibration
- flutter_tts (for audio feedback)

## Configuration

Key parameters to adjust in notebooks:

```python
# Audio processing
SAMPLE_RATE = 16000
MEL_COEFFICIENTS = 13
WINDOW_SIZE = 2048
HOP_LENGTH = 512

# Model training
EPOCHS = 15
BATCH_SIZE = 32
LEARNING_RATE = 0.001
VALIDATION_SPLIT = 0.2
```

## Performance and Optimization

- Model size: ~5-10 MB (optimized for mobile)
- Inference time: 10-100ms per sample
- Latency: <200ms from sound to haptic feedback
- Memory footprint: ~50-100 MB RAM during inference

## Troubleshooting

**Issue: Model fails to load in Flutter**
- Solution: Verify model is in .tflite format in assets/model.tflite
- Check file permissions and path configuration

**Issue: Poor classification accuracy**
- Solution: Expand training dataset with more samples
- Augment audio data using pitch shifting and time stretching
- Adjust model hyperparameters

**Issue: Slow inference on device**
- Solution: Quantize model to int8 format
- Reduce input feature dimensions
- Use YAMNet for faster inference

## Future Enhancements

- Multi-language support for labels
- Real-time model retraining on device
- Integration with CI/CD services
- Extended sound classification taxonomy
- Battery optimization improvements

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit pull requests with detailed descriptions
4. Ensure code follows best practices

## License

This project is open source and available for educational and accessibility purposes.

## Acknowledgments

- Built with TensorFlow and Flutter
- Inspired by accessibility needs of the deaf community
- Special thanks to contributors and testers

## Contact and Support

For questions, issues, or suggestions:
- Open an issue on GitHub
- Contact the maintainers directly
- Check existing documentation and notebooks

## References

- [TensorFlow Audio Processing](https://www.tensorflow.org/tutorials/audio)
- [Flutter Documentation](https://flutter.dev/docs)
- [YAMNet: Sound Event Detection](https://github.com/tensorflow/hub/tree/master/examples/colab/yamnet)
- [MFCC Feature Extraction](https://librosa.org/doc/main/generated/librosa.feature.mfcc.html)

---

**Last Updated:** 2026-04-30
**Version:** 1.0.0
**Status:** Active Development
