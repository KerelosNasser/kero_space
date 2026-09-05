package com.example.trobio

import android.service.voice.VoiceInteractionService
import android.util.Log

class TrobioVoiceInteractionService : VoiceInteractionService() {

    companion object {
        private const val TAG = "TrobioVoiceService"
        @Volatile var isServiceActive = false
    }

    override fun onReady() {
        super.onReady()
        isServiceActive = true
        Log.d(TAG, "TrobioVoiceInteractionService is ready as system assistant")
    }

    override fun onShutdown() {
        isServiceActive = false
        Log.d(TAG, "TrobioVoiceInteractionService shutdown")
        super.onShutdown()
    }
}
