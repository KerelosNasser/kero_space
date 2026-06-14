package com.example.kero_space

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.util.Log

class WakeWordService : Service() {
    private val TAG = "KeroSpaceWakeWord"
    
    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private lateinit var handlerThread: HandlerThread
    private lateinit var handler: Handler

    // ADB Intent for testing: adb shell am broadcast -a com.example.kero_space.WAKE_WORD_TRIGGER
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

        // Register Mock Trigger
        val filter = IntentFilter("com.example.kero_space.WAKE_WORD_TRIGGER")
        registerReceiver(mockTriggerReceiver, filter, RECEIVER_EXPORTED)

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
                    Log.e(TAG, "AudioRecord initialization failed")
                    return@post
                }

                audioRecord?.startRecording()
                isListening = true
                Log.d(TAG, "Started listening on AudioRecord")

                val buffer = ShortArray(160) // ~10ms chunk

                while (isListening) {
                    val readResult = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (readResult > 0) {
                        // TODO: Pass buffer to ONNX Model
                        // For Phase 2, we rely on the ADB broadcast trigger for validation
                    }
                }
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
        
        // Ensure we send this back to the main thread for EventSink
        // Add a 600ms buffer to allow Flutter engine to warm up if screen was off
        Handler(Looper.getMainLooper()).postDelayed({
            KeroSpaceForegroundService.wakeWordEventSink?.success(json)
        }, 600)
    }

    override fun onDestroy() {
        Log.d(TAG, "WakeWordService Destroyed")
        isListening = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        handlerThread.quitSafely()
        unregisterReceiver(mockTriggerReceiver)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
