package com.example.trobio

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.voice.VoiceInteractionSession
import android.service.voice.VoiceInteractionSessionService
import android.util.Log

class TrobioVoiceInteractionSessionService : VoiceInteractionSessionService() {
    override fun onNewSession(args: Bundle?): VoiceInteractionSession {
        return TrobioVoiceInteractionSession(this)
    }
}

class TrobioVoiceInteractionSession(context: Context) : VoiceInteractionSession(context) {

    companion object {
        private const val TAG = "TrobioVoiceSession"
    }

    override fun onShow(args: Bundle?, showFlags: Int) {
        super.onShow(args, showFlags)
        Log.d(TAG, "Voice interaction session triggered by OS gesture/assist. Launching Trobio voice...")
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("VOICE_WAKE_TRIGGERED", true)
        }
        try {
            startVoiceActivity(intent)
        } catch (_: Exception) {
            context.startActivity(intent)
        }
        hide()
    }
}
