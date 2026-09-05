package com.example.trobio.telemetry

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.security.GeneralSecurityException

data class AllowedWindow(val startHour: Int, val endHour: Int) {
    fun containsHour(hour: Int): Boolean = hour in startHour until endHour
}

data class ParsedRule(
    val packageName: String,
    val decisionBreakSeconds: Int = 30,
    val sessionLimitMinutes: Int? = null,
    val cooldownMinutes: Int? = null,
    val subAppTarget: String? = null,
    val allowedWindows: List<AllowedWindow> = emptyList(),
) {
    fun isAllowedAt(hour: Int): Boolean {
        if (allowedWindows.isEmpty()) return false
        return allowedWindows.any { it.containsHour(hour) }
    }
}

/**
 * Stores blacklist rules in EncryptedSharedPreferences with automatic corruption recovery
 * and zero-allocation in-memory caching.
 *
 * All lookups (getBlockedPackages, getRule) are O(1) in-memory lookups, completely
 * avoiding JSON parsing and cryptographic overhead on accessibility event threads.
 */
object BlacklistPreferencesStore {
    private const val TAG = "BlacklistStore"
    private const val PREFS_FILE = "kero_blacklist_prefs"
    private const val KEY_RULES = "blacklist_rules_json"

    @Volatile private var _prefs: SharedPreferences? = null

    // In-memory cache of parsed rules — rebuilt only on writes.
    @Volatile private var _cachedRulesMap: Map<String, ParsedRule>? = null

    // In-memory cache of raw JSON
    @Volatile private var _cachedRulesJson: String? = null

    private fun getPrefs(context: Context): SharedPreferences {
        _prefs?.let { return it }
        return synchronized(this) {
            _prefs ?: run {
                createEncryptedPrefsWithFallback(context).also { _prefs = it }
            }
        }
    }

    private fun createEncryptedPrefsWithFallback(context: Context): SharedPreferences {
        val appContext = context.applicationContext
        return try {
            val masterKey = MasterKey.Builder(appContext)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                appContext,
                PREFS_FILE,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
        } catch (e: Exception) {
            Log.e(TAG, "EncryptedSharedPreferences init failed (Keystore corrupted). Recovering...", e)
            try {
                // Clear corrupt preferences file
                val file = File(appContext.filesDir.parent, "shared_prefs/$PREFS_FILE.xml")
                if (file.exists()) {
                    file.delete()
                }
                val masterKey = MasterKey.Builder(appContext)
                    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                    .build()
                EncryptedSharedPreferences.create(
                    appContext,
                    PREFS_FILE,
                    masterKey,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
                )
            } catch (fallbackEx: Exception) {
                Log.e(TAG, "Fallback to standard SharedPreferences due to fatal Keystore failure", fallbackEx)
                appContext.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
            }
        }
    }

    fun saveRulesJson(context: Context, json: String) {
        val parsedMap = parseJsonToRulesMap(json)
        synchronized(this) {
            _cachedRulesJson = json
            _cachedRulesMap = parsedMap
        }
        try {
            getPrefs(context).edit().putString(KEY_RULES, json).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist rules to preferences: ${e.message}", e)
        }
    }

    fun getRulesJson(context: Context): String {
        _cachedRulesJson?.let { return it }
        return synchronized(this) {
            _cachedRulesJson?.let { return it }
            val json = try {
                getPrefs(context).getString(KEY_RULES, "[]") ?: "[]"
            } catch (e: Exception) {
                Log.e(TAG, "Error reading rules JSON", e)
                "[]"
            }
            _cachedRulesJson = json
            if (_cachedRulesMap == null) {
                _cachedRulesMap = parseJsonToRulesMap(json)
            }
            json
        }
    }

    fun getRulesMap(context: Context): Map<String, ParsedRule> {
        _cachedRulesMap?.let { return it }
        return synchronized(this) {
            _cachedRulesMap?.let { return it }
            val map = parseJsonToRulesMap(getRulesJson(context))
            _cachedRulesMap = map
            map
        }
    }

    fun getRule(context: Context, packageName: String): ParsedRule? {
        return getRulesMap(context)[packageName]
    }

    /**
     * Returns the set of blocked package names with zero JSON parsing overhead.
     */
    fun getBlockedPackages(context: Context): Set<String> {
        return getRulesMap(context).keys
    }

    fun parseJsonToRulesMap(json: String): Map<String, ParsedRule> {
        val result = mutableMapOf<String, ParsedRule>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val pkg = obj.optString("packageName").takeIf { it.isNotEmpty() } ?: continue
                val breakSeconds = obj.optInt("decisionBreakSeconds", 30)
                val sessionLimit = if (obj.has("sessionLimitMinutes")) obj.optInt("sessionLimitMinutes") else null
                val cooldown = if (obj.has("cooldownMinutes")) obj.optInt("cooldownMinutes") else null
                val subApp = if (obj.has("subAppTarget")) obj.optString("subAppTarget").takeIf { it.isNotEmpty() } else null

                val allowedWindows = mutableListOf<AllowedWindow>()
                val windowsArr = obj.optJSONArray("allowedWindows")
                if (windowsArr != null) {
                    for (j in 0 until windowsArr.length()) {
                        val wObj = windowsArr.optJSONObject(j) ?: continue
                        allowedWindows.add(
                            AllowedWindow(
                                startHour = wObj.optInt("startHour", 0),
                                endHour = wObj.optInt("endHour", 24),
                            )
                        )
                    }
                }

                result[pkg] = ParsedRule(
                    packageName = pkg,
                    decisionBreakSeconds = breakSeconds,
                    sessionLimitMinutes = sessionLimit,
                    cooldownMinutes = cooldown,
                    subAppTarget = subApp,
                    allowedWindows = allowedWindows,
                )
            }
        } catch (e: Exception) {
            try {
                Log.e(TAG, "Error parsing rules JSON into map: ${e.message}")
            } catch (_: Throwable) {}
        }
        return result
    }
}
