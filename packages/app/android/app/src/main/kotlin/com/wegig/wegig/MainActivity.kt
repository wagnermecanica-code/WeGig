package com.wegig.wegig

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.tiktok.TikTokBusinessSdk
import com.tiktok.appevents.base.EventName
import com.tiktok.appevents.base.TTBaseEvent
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wegig.wegig/tiktok"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "trackEvent" -> {
                    val eventName = call.argument<String>("eventName")
                    if (eventName != null) {
                        try {
                            val event = TTBaseEvent(eventName, JSONObject(), "")
                            TikTokBusinessSdk.trackTTEvent(event)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("TIKTOK_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "eventName is required", null)
                    }
                }
                "identify" -> {
                    val externalId = call.argument<String>("externalId") ?: ""
                    val userName = call.argument<String>("userName") ?: ""
                    val phone = call.argument<String>("phone") ?: ""
                    val email = call.argument<String>("email") ?: ""
                    try {
                        TikTokBusinessSdk.identify(externalId, userName, phone, email)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("TIKTOK_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
