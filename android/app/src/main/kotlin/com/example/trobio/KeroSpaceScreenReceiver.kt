package com.example.trobio

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class KeroSpaceScreenReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "KeroSpaceScreen"
    }

    object SessionStateHolder {
        @Volatile var lastWakeTimestamp: Long = 0L
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val timestamp = System.currentTimeMillis()
        
        var sessionDurationMs = 0L
        val type = when (action) {
            Intent.ACTION_SCREEN_ON -> {
                SessionStateHolder.lastWakeTimestamp = timestamp
                "WAKE"
            }
            Intent.ACTION_SCREEN_OFF -> {
                if (SessionStateHolder.lastWakeTimestamp > 0) {
                    sessionDurationMs = timestamp - SessionStateHolder.lastWakeTimestamp
                }
                "SLEEP"
            }
            Intent.ACTION_USER_PRESENT -> "UNLOCK"
            else -> return
        }

        Log.d(TAG, "Screen Event: $type")
        
        // Construct JSON manually since we don't have Gson/Moshi setup specified yet
        val json = "{\"type\":\"$type\",\"timestamp\":$timestamp,\"sessionDurationMs\":$sessionDurationMs}"
        
        // Push to both engines so both the UI (TelemetryBloc) and
        // the background isolate (Isar writer) receive the event.
        KeroSpaceForegroundService.screenEventSink?.success(json)
        KeroSpaceForegroundService.bgScreenEventSink?.success(json)
    }
}

