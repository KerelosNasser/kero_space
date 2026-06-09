package com.example.kero_space

import android.content.Context
import android.database.Cursor
import android.provider.CalendarContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class CalendarChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getEvents") {
            try {
                val events = getLocalEvents()
                result.success(events)
            } catch (e: SecurityException) {
                result.error("PERMISSION_DENIED", "Calendar permission denied", null)
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
            }
        } else {
            result.notImplemented()
        }
    }

    private fun getLocalEvents(): String {
        val jsonArray = JSONArray()
        val projection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.DTEND,
            CalendarContract.Events.ALL_DAY
        )
        
        val now = System.currentTimeMillis()
        val startMillis = now - (30L * 24 * 60 * 60 * 1000)
        val endMillis = now + (90L * 24 * 60 * 60 * 1000)
        
        val selection = "${CalendarContract.Events.DTSTART} >= ? AND ${CalendarContract.Events.DTSTART} <= ?"
        val selectionArgs = arrayOf(startMillis.toString(), endMillis.toString())

        val cursor: Cursor? = context.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            "${CalendarContract.Events.DTSTART} ASC"
        )

        cursor?.use {
            val idIdx = it.getColumnIndex(CalendarContract.Events._ID)
            val titleIdx = it.getColumnIndex(CalendarContract.Events.TITLE)
            val startIdx = it.getColumnIndex(CalendarContract.Events.DTSTART)
            val endIdx = it.getColumnIndex(CalendarContract.Events.DTEND)
            val allDayIdx = it.getColumnIndex(CalendarContract.Events.ALL_DAY)

            while (it.moveToNext()) {
                val obj = JSONObject()
                obj.put("id", it.getLong(idIdx).toString())
                obj.put("title", it.getString(titleIdx) ?: "Untitled")
                obj.put("startTime", it.getLong(startIdx))
                obj.put("endTime", it.getLong(endIdx))
                obj.put("allDay", it.getInt(allDayIdx) == 1)
                jsonArray.put(obj)
            }
        }
        return jsonArray.toString()
    }
}
