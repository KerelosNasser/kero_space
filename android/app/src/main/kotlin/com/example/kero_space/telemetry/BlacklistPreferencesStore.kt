package com.example.kero_space.telemetry

import android.content.Context
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONArray

/**
 * Stores blacklist rules in EncryptedSharedPreferences.
 *
 * IMPORTANT: EncryptedSharedPreferences is slow to construct.
 * We cache the instance after first creation to avoid re-initialising
 * the key on every accessibility event (which fires hundreds of times/min).
 *
 * getBlockedPackages() is called on every TYPE_WINDOW_STATE_CHANGED event.
 * Results are cached in [_cachedPackages] and only re-parsed when the store
 * is mutated via [saveRulesJson].
 */
object BlacklistPreferencesStore {
    private const val TAG = "BlacklistStore"
    private const val PREFS_FILE = "kero_blacklist_prefs"
    private const val KEY_RULES = "blacklist_rules_json"

    // Lazy-initialised, cached SharedPreferences instance.
    @Volatile private var _prefs: EncryptedSharedPreferences? = null

    // In-memory cache of blocked package names — rebuilt only on writes.
    @Volatile private var _cachedPackages: Set<String>? = null

    private fun getPrefs(context: Context): EncryptedSharedPreferences {
        _prefs?.let { return it }
        return synchronized(this) {
            _prefs ?: run {
                val masterKey = MasterKey.Builder(context.applicationContext)
                    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                    .build()
                (EncryptedSharedPreferences.create(
                    context.applicationContext,
                    PREFS_FILE,
                    masterKey,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
                ) as EncryptedSharedPreferences).also { _prefs = it }
            }
        }
    }

    fun saveRulesJson(context: Context, json: String) {
        getPrefs(context).edit().putString(KEY_RULES, json).apply()
        synchronized(this) {
            _cachedPackages = null // Invalidate cache on write
        }
    }

    fun getRulesJson(context: Context): String =
        getPrefs(context).getString(KEY_RULES, "[]") ?: "[]"

    /**
     * Returns the set of blocked package names.
     * Result is cached in memory and only rebuilt when [saveRulesJson] is called.
     * Safe to call from every accessibility event.
     */
    fun getBlockedPackages(context: Context): Set<String> {
        _cachedPackages?.let { return it }
        return synchronized(this) {
            _cachedPackages?.let { return it }
            try {
                val arr = JSONArray(getRulesJson(context))
                val packages = (0 until arr.length())
                    .map { arr.getJSONObject(it).getString("packageName") }
                    .toSet()
                _cachedPackages = packages
                packages
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse blacklist rules JSON — returning empty set", e)
                emptySet()
            }
        }
    }
}
