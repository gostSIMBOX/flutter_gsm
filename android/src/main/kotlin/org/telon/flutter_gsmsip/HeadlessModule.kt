package org.telon.flutter_gsmsip

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * HeadlessModule - Flutter method channel handler for headless service operations
 *
 * Provides Dart API for:
 * - startService(): Start the headless background service
 * - stopService(): Stop the headless background service
 * - toForeground(): Bring the app to foreground
 */
class HeadlessModule : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "HeadlessModule"
        private const val CHANNEL = "flutter_gsmsip/headless"

        // Handler thread for background operations
        @Volatile
        private var handlerThread: HandlerThread? = null

        @Volatile
        private var handler: Handler? = null

        /**
         * Initialize the handler thread with foreground priority
         */
        fun initializeHandler() {
            if (handlerThread == null) {
                handlerThread = HandlerThread("HeadlessModuleThread", android.os.Process.THREAD_PRIORITY_FOREGROUND)
                handlerThread?.start()
                handler = Handler(handlerThread!!.looper)
                Log.i(TAG, "Handler thread initialized")
            }
        }

        /**
         * Get the shared handler instance
         */
        fun getHandler(): Handler? = handler
    }

    private var channel: MethodChannel? = null
    private var applicationContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "HeadlessModule attached to engine")
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "HeadlessModule detached from engine")
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startService" -> startService(result)
            "stopService" -> stopService(result)
            "toForeground" -> toForeground(result)
            else -> result.notImplemented()
        }
    }

    private fun startService(result: MethodChannel.Result) {
        Log.i(TAG, "startService called")
        try {
            initializeHandler()
            val context = applicationContext
                ?: return result.error("NO_CONTEXT", "Application context not available", null)

            val intent = Intent(context, HeadlessService::class.java)
            context.startForegroundService(intent)
            Log.i(TAG, "HeadlessService started")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start HeadlessService", e)
            result.error("START_SERVICE_FAILED", e.message, null)
        }
    }

    private fun stopService(result: MethodChannel.Result) {
        Log.i(TAG, "stopService called")
        try {
            val context = applicationContext
                ?: return result.error("NO_CONTEXT", "Application context not available", null)

            val intent = Intent(context, HeadlessService::class.java)
            context.stopService(intent)
            Log.i(TAG, "HeadlessService stopped")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop HeadlessService", e)
            result.error("STOP_SERVICE_FAILED", e.message, null)
        }
    }

    private fun toForeground(result: MethodChannel.Result) {
        Log.i(TAG, "toForeground called")
        try {
            val context = applicationContext
                ?: return result.error("NO_CONTEXT", "Application context not available", null)

            // Launch the app using FlutterActivity
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            intent?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("foreground", true)
            }
            intent?.let { context.startActivity(it) }
            Log.i(TAG, "App brought to foreground")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to bring app to foreground", e)
            result.error("TO_FOREGROUND_FAILED", e.message, null)
        }
    }
}
