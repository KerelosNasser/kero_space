package com.example.kero_space

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "kero_space/main_methods"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startForegroundService") {
                val serviceIntent = Intent(this, KeroSpaceForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                result.success("Started")
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/calendar").setMethodCallHandler(
            CalendarChannelHandler(this)
        )

        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/wake_word").setStreamHandler(
            object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    KeroSpaceForegroundService.wakeWordEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    KeroSpaceForegroundService.wakeWordEventSink = null
                }
            }
        )

        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/screen_events").setStreamHandler(
            object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    KeroSpaceForegroundService.screenEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    KeroSpaceForegroundService.screenEventSink = null
                }
            }
        )

        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/accessibility").setStreamHandler(
            object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    KeroSpaceForegroundService.accessibilityEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    KeroSpaceForegroundService.accessibilityEventSink = null
                }
            }
        )
    }
}
