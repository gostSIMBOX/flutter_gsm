package org.telon.flutter_gsmsip

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterGsmsipPlugin - Main plugin entry point
 * 
 * Registers all native modules and provides unified API to Dart.
 */
class FlutterGsmsipPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    
    companion object {
        private const val TAG = "FlutterGsmsipPlugin"
        private const val CHANNEL = "flutter_gsmsip"
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
            
            else -> result.notImplemented()
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
