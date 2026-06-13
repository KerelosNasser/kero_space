# Wake Word Training & Implementation

## Current Architecture
The app listens for system intents or manual button presses to trigger the Voice overlay.
The `WakeWordAgent` is designed as a background service listening for a specific phrase (e.g. "Hey Kero").

## Implementation Path: OpenWakeWord
We will use an ONNX-based wake word engine running locally on-device.

1. **Audio Capture:** Use `AudioRecord` in Android to capture rolling 16kHz audio.
2. **Feature Extraction:** Extract Mel-spectrograms from the audio buffers.
3. **Model:** Load an `.onnx` custom wake word model.
4. **Inference:** Run the ONNX model using `onnxruntime-android`.

## Training a Custom Wake Word
To train a model for "Hey Kero" (or any other phrase):

1. Clone the `openwakeword` repository.
2. Collect audio samples (~500 samples of varying pitch/speed).
3. Alternatively, use the automated synthesis pipeline in `openwakeword` to generate samples using TTS engines.
4. Train the model using the provided Colab notebooks or local GPU.
5. Export to ONNX.
6. Place the `.onnx` file in the Flutter `assets/models/` directory.

### Power Considerations
Continuous listening can drain battery. The background service must:
- Use `AudioRecord` with power-saving profiles.
- Run the ONNX model only when audio energy (VAD) exceeds a noise floor threshold.
- Target <2% battery drain per hour.
