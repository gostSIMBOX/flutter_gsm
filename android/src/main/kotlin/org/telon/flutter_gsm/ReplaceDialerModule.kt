package org.telon.flutter_gsm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telecom.TelecomManager
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * ReplaceDialerModule - Native Android module for default dialer management
 */
class ReplaceDialerModule : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val TAG = "ReplaceDialerModule"
        private const val CHANNEL = "flutter_gsm/replace_dialer"
        private const val RC_DEFAULT_PHONE = 3289
    }

    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var channel: MethodChannel? = null
    private var callback: Result? = null

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
        binding.addActivityResultListener { requestCode, resultCode, data ->
            if (requestCode == RC_DEFAULT_PHONE) {
                handleActivityResult(resultCode)
                true
            } else {
                false
            }
        }
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
            "isDefaultDialer" -> handleIsDefaultDialer(result)
            "setDefaultDialer" -> handleSetDefaultDialer(result)
            "canSetDefaultDialer" -> handleCanSetDefaultDialer(result)
            else -> result.notImplemented()
        }
    }

    private fun handleIsDefaultDialer(result: Result) {
        try {
            val telecomManager = applicationContext?.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            val packageName = applicationContext?.packageName
            val isDefault = telecomManager?.defaultDialerPackage == packageName
            result.success(isDefault)
        } catch (e: Exception) {
            Log.e(TAG, "isDefaultDialer failed", e)
            result.error("CHECK_FAILED", e.message, null)
        }
    }

    private fun handleSetDefaultDialer(result: Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val telecomManager = applicationContext?.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                val newDefaultDialer = applicationContext?.packageName ?: ""
                
                if (telecomManager != null && telecomManager.defaultDialerPackage != newDefaultDialer) {
                    val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                    intent.putExtra("android.telecom.extra.DEFAULT_DIALER_PACKAGE", newDefaultDialer)
                    activity?.startActivityForResult(intent, RC_DEFAULT_PHONE)
                    callback = result
                } else {
                    result.success(true)
                }
            } else {
                result.success(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "setDefaultDialer failed", e)
            result.error("SET_FAILED", e.message, null)
        }
    }

    private fun handleCanSetDefaultDialer(result: Result) {
        try {
            val canSet = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
            result.success(canSet)
        } catch (e: Exception) {
            Log.e(TAG, "canSetDefaultDialer failed", e)
            result.error("CHECK_FAILED", e.message, null)
        }
    }

    private fun handleActivityResult(resultCode: Int) {
        if (resultCode == Activity.RESULT_OK) {
            Log.i(TAG, "Default dialer set successfully")
            callback?.success(true)
        } else {
            Log.w(TAG, "Default dialer set cancelled")
            callback?.success(false)
        }
        callback = null
    }
}
