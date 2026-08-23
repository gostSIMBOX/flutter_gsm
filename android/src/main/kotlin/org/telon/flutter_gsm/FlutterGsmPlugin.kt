package org.telon.flutter_gsm

import android.content.Context
import android.content.pm.PackageManager
import android.telephony.SubscriptionManager
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterGsmPlugin - Main plugin entry point
 * 
 * Registers all native modules and provides unified API to Dart.
 */
class FlutterGsmPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    
    companion object {
        private const val TAG = "FlutterGsmPlugin"
        private const val CHANNEL = "flutter_gsm"
    }

    private lateinit var channel: MethodChannel
    private var gatewayDialerModule: GatewayDialerModule? = null
    private var replaceDialerModule: ReplaceDialerModule? = null
    private var applicationContext: Context? = null
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        
        applicationContext = binding.applicationContext
        
        // Setup main method channel
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        
        // Initialize and register GatewayDialerModule
        gatewayDialerModule = GatewayDialerModule()
        gatewayDialerModule?.onAttachedToEngine(binding)
        
        // Initialize and register ReplaceDialerModule
        replaceDialerModule = ReplaceDialerModule()
        replaceDialerModule?.onAttachedToEngine(binding)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Core plugin methods
            "initialize" -> handleInitialize(result)
            "makeCall" -> handleMakeCall(call, result)
            "sendSms" -> handleSendSms(call, result)
            "getStatus" -> handleGetStatus(result)
            "dispose" -> handleDispose(result)

            // Modem/SIM discovery (AndroidFlutterGsm's listModems() source —
            // flutter_tele/flutter_dialer provide no subscription enumeration,
            // see flows/sdd-flutter_gsm/04-implementation-log.md Task 4)
            "getActiveSims" -> handleGetActiveSims(result)

            else -> result.notImplemented()
        }
    }

    /**
     * Enumerates active SIM subscriptions via [SubscriptionManager]. Returns
     * an empty list (not an error) if READ_PHONE_STATE isn't granted — the
     * Dart side treats that as "no known SIMs", distinct from "driver not
     * available". Permission requesting is the Dart/app's responsibility
     * (via permission_handler), not this plugin's.
     */
    private fun handleGetActiveSims(result: MethodChannel.Result) {
        val context = applicationContext
        if (context == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasPermission) {
            Log.w(TAG, "getActiveSims: READ_PHONE_STATE not granted, returning empty list")
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        try {
            val subscriptionManager =
                context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val subscriptions = subscriptionManager.activeSubscriptionInfoList ?: emptyList()

            val sims = subscriptions.map { info ->
                mapOf(
                    "slotIndex" to info.simSlotIndex,
                    "subscriptionId" to info.subscriptionId,
                    "carrierName" to info.carrierName?.toString(),
                    "displayName" to info.displayName?.toString(),
                    "number" to info.number,
                )
            }
            result.success(sims)
        } catch (e: SecurityException) {
            Log.w(TAG, "getActiveSims: SecurityException despite permission check: ${e.message}")
            result.success(emptyList<Map<String, Any?>>())
        }
    }

    private fun handleInitialize(result: MethodChannel.Result) {
        Log.i(TAG, "initialize called")
        // TODO: Implement proper initialization with SIP/SMPP
        result.success(true)
    }

    private fun handleMakeCall(call: MethodCall, result: MethodChannel.Result) {
        val destination = call.argument<String>("destination")
        Log.i(TAG, "makeCall: $destination")
        
        gatewayDialerModule?.makeCall(destination, result)
            ?: result.error("NOT_INITIALIZED", "GatewayDialerModule not initialized", null)
    }

    private fun handleSendSms(call: MethodCall, result: MethodChannel.Result) {
        val destination = call.argument<String>("destination")
        val message = call.argument<String>("message")
        Log.i(TAG, "sendSms to $destination: $message")
        
        // TODO: Implement SMS sending via TelephonyManager
        result.success(true)
    }

    private fun handleGetStatus(result: MethodChannel.Result) {
        Log.i(TAG, "getStatus called")
        result.success(mapOf(
            "isRunning" to true,
            "sipRegistered" to false,
            "gsmSignal" to 0
        ))
    }

    private fun handleDispose(result: MethodChannel.Result) {
        Log.i(TAG, "dispose called")
        result.success(true)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine")
        
        channel.setMethodCallHandler(null)
        gatewayDialerModule?.onDetachedFromEngine(binding)
        replaceDialerModule?.onDetachedFromEngine(binding)
        
        gatewayDialerModule = null
        replaceDialerModule = null
        applicationContext = null
    }
}
