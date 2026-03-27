package org.telon.flutter_gsmsip

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * GatewayDialerModule - Native Android module for dialer functionality
 */
class GatewayDialerModule : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val TAG = "GatewayDialerModule"
        private const val CHANNEL = "flutter_gsmsip/dialer"
    }

    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine")
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onDetachedFromEngine")
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "onAttachedToActivity")
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "onDetachedFromActivity")
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "onReattachedToActivityForConfigChanges")
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "onDetachedFromActivityForConfigChanges")
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "makeCall" -> handleMakeCall(call, result)
            "getSignalStrength" -> handleGetSignalStrength(result)
            "getPhoneNumber" -> handleGetPhoneNumber(result)
            "getNetworkOperator" -> handleGetNetworkOperator(result)
            else -> result.notImplemented()
        }
    }

    private fun handleMakeCall(call: MethodCall, result: Result) {
        val number = call.argument<String>("number")
        Log.d(TAG, "makeCall: $number")

        try {
            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            applicationContext?.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "makeCall failed", e)
            result.error("CALL_FAILED", e.message, null)
        }
    }

    private fun handleGetSignalStrength(result: Result) {
        try {
            // Simplified signal strength - in real implementation use TelephonyManager
            result.success(mapOf("dbm" to -80, "asu" to 20))
        } catch (e: Exception) {
            Log.e(TAG, "getSignalStrength failed", e)
            result.error("SIGNAL_FAILED", e.message, null)
        }
    }

    private fun handleGetPhoneNumber(result: Result) {
        try {
            result.success(null) // Requires READ_PHONE_STATE permission
        } catch (e: Exception) {
            Log.e(TAG, "getPhoneNumber failed", e)
            result.error("PHONE_FAILED", e.message, null)
        }
    }

    private fun handleGetNetworkOperator(result: Result) {
        try {
            result.success(null) // Requires READ_PHONE_STATE permission
        } catch (e: Exception) {
            Log.e(TAG, "getNetworkOperator failed", e)
            result.error("NETWORK_FAILED", e.message, null)
        }
    }

    /**
     * Make a call - called from FlutterGsmsipPlugin
     */
    fun makeCall(number: String?, result: Result) {
        val call = MethodCall("makeCall", mapOf("number" to number))
        onMethodCall(call, result)
    }
}
