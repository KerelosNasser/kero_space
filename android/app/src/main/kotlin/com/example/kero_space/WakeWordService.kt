package com.example.kero_space

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.util.Log

class WakeWordService : Service() {

    companion object {
        private const val TAG = "KeroSpaceWakeWord"
    }

    @Volatile private var audioRecord: AudioRecord? = null
    @Volatile private var isListening = false

    private lateinit var handlerThread: HandlerThread
    private lateinit var handler: Handler

    /**
     * ADB mock trigger for dev/test only.
     * Not exported — ADB can still reach it via:
     *   adb shell am broadcast --user 0 -a com.example.kero_space.WAKE_WORD_TRIGGER
     */
    private val mockTriggerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d(TAG, "Mock Wake Word Trigger received via ADB")
            emitWakeWordEvent("hey kero", 0.99f)
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "WakeWordService Created")

        handlerThread = HandlerThread("WakeWordAudioThread")
        handlerThread.start()
        handler = Handler(handlerThread.looper)

        // RECEIVER_NOT_EXPORTED: ADB broadcasts can still trigger this via --user 0.
        // Using EXPORTED here is a security risk — any installed app could trigger fake wakes.
        val filter = IntentFilter("com.example.kero_space.WAKE_WORD_TRIGGER")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(mockTriggerReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(mockTriggerReceiver, filter)
        }

        startListening()
    }

    private fun startListening() {
        handler.post {
            try {
                val sampleRate = 16000
                val channelConfig = AudioFormat.CHANNEL_IN_MONO
                val audioFormat = AudioFormat.ENCODING_PCM_16BIT
                val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    channelConfig,
                    audioFormat,
                    bufferSize
                )

                if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                    Log.e(TAG, "AudioRecord initialization failed — no microphone permission?")
                    return@post
                }

                audioRecord?.startRecording()
                isListening = true
                Log.d(TAG, "Started listening on AudioRecord")

                val buffer = ShortArray(160) // ~10ms chunk at 16kHz

                while (isListening) {
                    val readResult = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (readResult > 0) {
                        // TODO Phase 2: Pass buffer to ONNX WakeWord model.
                        // For Phase 1 validation, rely on the ADB broadcast trigger.
                    }
                }

                Log.d(TAG, "Audio loop exited.")
            } catch (e: SecurityException) {
                Log.e(TAG, "Microphone permission denied", e)
            } catch (e: Exception) {
                Log.e(TAG, "Error in audio loop", e)
            }
        }
    }

    private fun emitWakeWordEvent(text: String, confidence: Float) {
        val json = "{\"type\":\"WAKE_WORD_DETECTED\",\"text\":\"$text\",\"confidence\":$confidence,\"timestamp\":${System.currentTimeMillis()}}"

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("VOICE_WAKE_TRIGGERED", true)
        }
        startActivity(launchIntent)

        // Post to main thread with a buffer to allow the Flutter engine to warm up
        // if the screen was off when the wake word was detected.
        Handler(Looper.getMainLooper()).postDelayed({
            KeroSpaceForegroundService.wakeWordEventSink?.success(json)
        }, 600)
    }

    override fun onDestroy() {
        Log.d(TAG, "WakeWordService Destroyed")
        isListening = false
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing AudioRecord", e)
        }
        audioRecord = null
        handlerThread.quitSafely()
        try {
            unregisterReceiver(mockTriggerReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Error unregistering mock trigger receiver", e)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
