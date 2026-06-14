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
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import java.nio.FloatBuffer
import java.util.Arrays

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

                val env = OrtEnvironment.getEnvironment()
                var session: OrtSession? = null
                try {
                    val modelBytes = applicationContext.assets.open("hey_kero.onnx").readBytes()
                    session = env.createSession(modelBytes)
                    Log.d(TAG, "ONNX model loaded successfully.")
                } catch (e: Exception) {
                    Log.w(TAG, "ONNX model 'hey_kero.onnx' not found in assets or failed to load.", e)
                }

                val buffer = ShortArray(160) // ~10ms chunk at 16kHz
                val frameBuffer = FloatArray(16000) // 1 second rolling window

                while (isListening) {
                    val readResult = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (readResult > 0) {
                        // Shift frameBuffer
                        System.arraycopy(frameBuffer, readResult, frameBuffer, 0, frameBuffer.size - readResult)
                        for (i in 0 until readResult) {
                            frameBuffer[frameBuffer.size - readResult + i] = buffer[i] / 32768.0f // Normalize to [-1, 1]
                        }

                        // Run inference if session exists
                        session?.let { ortSession ->
                            try {
                                val inputName = ortSession.inputNames.iterator().next()
                                val shape = longArrayOf(1, 16000)
                                val tensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(frameBuffer), shape)
                                
                                val result = ortSession.run(mapOf(inputName to tensor))
                                val outputArray = result[0].value
                                
                                // Handling possible 1D or 2D output array
                                val confidence = if (outputArray is Array<*> && outputArray.isNotEmpty() && outputArray[0] is FloatArray) {
                                    (outputArray as Array<FloatArray>)[0][0]
                                } else if (outputArray is FloatArray && outputArray.isNotEmpty()) {
                                    outputArray[0]
                                } else {
                                    0f
                                }

                                if (confidence > 0.85f) {
                                    Log.d(TAG, "Wake word detected by ONNX! Confidence: $confidence")
                                    emitWakeWordEvent("hey kero", confidence)
                                    // Reset buffer to avoid duplicate triggers
                                    Arrays.fill(frameBuffer, 0f)
                                }
                                
                                result.close()
                                tensor.close()
                            } catch (e: Exception) {
                                Log.e(TAG, "Error running ONNX inference", e)
                            }
                        }
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
