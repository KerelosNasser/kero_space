package com.example.kero_space.telemetry

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONArray

object BlacklistPreferencesStore {
    private const val PREFS_FILE = "kero_blacklist_prefs"
    private const val KEY_RULES = "blacklist_rules_json"

    private fun getPrefs(context: Context) = EncryptedSharedPreferences.create(
        context, PREFS_FILE,
        MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveRulesJson(context: Context, json: String) =
        getPrefs(context).edit().putString(KEY_RULES, json).apply()

    fun getRulesJson(context: Context): String =
        getPrefs(context).getString(KEY_RULES, "[]") ?: "[]"

    fun getBlockedPackages(context: Context): Set<String> {
        val arr = JSONArray(getRulesJson(context))
        return (0 until arr.length()).map { arr.getJSONObject(it).getString("packageName") }.toSet()
    }
}
