package com.example.trobio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import org.json.JSONObject
import java.nio.FloatBuffer
import java.util.Arrays

class WakeWordService : Service() {

    companion object {
        private const val TAG = "KeroSpaceWakeWord"
        private const val CHANNEL_ID = "kero_space_wake_word_channel"
        private const val NOTIFICATION_ID = 2

        @Volatile var isRunning = false
    }

    @Volatile private var audioRecord: AudioRecord? = null
    @Volatile private var isListening = false

    private lateinit var handlerThread: HandlerThread
    private lateinit var handler: Handler

    private var mockReceiverRegistered = false

    /**
     * ADB mock trigger for dev/test only.
     * Not exported — ADB can still reach it via:
     *   adb shell am broadcast --user 0 -a com.example.trobio.WAKE_WORD_TRIGGER
     */
    private val mockTriggerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d(TAG, "Mock Wake Word Trigger received via ADB")
            emitWakeWordEvent("hey kero", 0.99f)
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        Log.d(TAG, "WakeWordService Created")

        handlerThread = HandlerThread("WakeWordAudioThread")
        handlerThread.start()
        handler = Handler(handlerThread.looper)

        val isDebuggable = (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) {
            val filter = IntentFilter("com.example.trobio.WAKE_WORD_TRIGGER")
            ContextCompat.registerReceiver(this, mockTriggerReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
            mockReceiverRegistered = true
        }

        createNotificationChannel()
        startForegroundWithNotification()

        startListening()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Trobio Wake Word",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { description = "Listening for wake word" }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val notification: Notification = androidx.core.app.NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Trobio Listening")
            .setContentText("Wake word detection active")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val hasMic = ContextCompat.checkSelfPermission(
                this, android.Manifest.permission.RECORD_AUDIO,
            ) == PackageManager.PERMISSION_GRANTED
            val serviceTypes = if (hasMic) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            } else {
                Log.w(TAG, "RECORD_AUDIO not granted — falling back to no FGS type")
                0
            }
            if (serviceTypes != 0) {
                startForeground(NOTIFICATION_ID, notification, serviceTypes)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
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
        val json = JSONObject().apply {
            put("type", "WAKE_WORD_DETECTED")
            put("text", text)
            put("confidence", confidence.toDouble())
            put("timestamp", System.currentTimeMillis())
        }.toString()

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
        isRunning = false
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
        if (mockReceiverRegistered) {
            try {
                unregisterReceiver(mockTriggerReceiver)
            } catch (e: Exception) {
                Log.w(TAG, "Error unregistering mock trigger receiver", e)
            }
            mockReceiverRegistered = false
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

