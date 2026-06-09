package com.example.kero_space

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class KeroSpaceScreenReceiver : BroadcastReceiver() {
    private val TAG = "KeroSpaceScreen"

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val timestamp = System.currentTimeMillis()
        
        val type = when (action) {
            Intent.ACTION_SCREEN_ON -> "WAKE"
            Intent.ACTION_SCREEN_OFF -> "SLEEP"
            Intent.ACTION_USER_PRESENT -> "UNLOCK"
            else -> return
        }

        Log.d(TAG, "Screen Event: \$type")
        
        // Construct JSON manually since we don't have Gson/Moshi setup specified yet
        val json = "{\"type\":\"\$type\",\"timestamp\":\$timestamp}"
        
        // Push to Dart via EventChannel Sink
        KeroSpaceForegroundService.screenEventSink?.success(json)
    }
}
