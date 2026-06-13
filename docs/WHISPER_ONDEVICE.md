# On-Device STT (Whisper / Local Speech)

## Current Architecture (V1)
Currently, `VoiceBloc` uses the standard `speech_to_text` plugin with the `onDevice: true` flag. This leverages Android's built-in offline voice recognition.
- **Requirement:** User must have downloaded the offline language pack (English) in their Android Settings > Google > Search, Assistant & Voice > Voice > Offline speech recognition.

## Future Architecture (V2 - Whisper.cpp)
For true 100% offline, privacy-first STT without depending on Google Play Services, the plan is to integrate `whisper.cpp` via Dart FFI.

### Implementation Path
1. **Include flutter_whisper / whisper.cpp:** Add the `whisper_cpp` package or compile `whisper.cpp` natively for Android.
2. **Model:** Download the `ggml-tiny.en.bin` model (approx 39MB).
3. **Execution:** Load the model into memory upon `VoiceBloc` initialization.
4. **Processing:** Feed PCM audio chunks (16kHz, 16-bit mono) from `AudioRecord` directly into the Whisper decoder.
5. **Output:** Whisper returns the transcribed string, which is then passed to `CommandParser`.

### Performance Targets
- **Model:** `tiny.en`
- **RAM usage:** < 150MB
- **Inference Speed:** < 500ms on modern Snapdragons.
