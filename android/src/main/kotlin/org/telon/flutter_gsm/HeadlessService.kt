package org.telon.flutter_gsm

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * HeadlessService - Foreground service for persistent background execution
 */
class HeadlessService : Service() {

    companion object {
        private const val TAG = "HeadlessService"
        private const val SERVICE_NOTIFICATION_ID = 123456
        private const val CHANNEL_ID = "HEADLESS_SERVICE_CHANNEL"
        private const val CHANNEL_NAME = "Headless Service"
        private const val EXECUTION_INTERVAL_MS = 2000L

        @Volatile
        private var isRunningFlag = false

        fun isRunning(): Boolean = isRunningFlag
    }

    private val handler = Handler(Looper.getMainLooper())
    private var isRunning = false

    private val recurringTask = object : Runnable {
        override fun run() {
            if (isRunning) {
                executeHeadlessTask()
                handler.postDelayed(this, EXECUTION_INTERVAL_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "HeadlessService created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "HeadlessService started")

        createNotificationChannel()
        val notification = buildNotification()
        startForeground(SERVICE_NOTIFICATION_ID, notification)

        isRunning = true
        isRunningFlag = true
        handler.post(recurringTask)

        return START_STICKY
    }

    override fun onDestroy() {
        Log.i(TAG, "HeadlessService destroyed")
        isRunning = false
        isRunningFlag = false
        handler.removeCallbacks(recurringTask)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background service"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val notificationIntent = Intent(this, java.lang.Object::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Headless Service")
            .setContentText("Running background tasks")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun executeHeadlessTask() {
        Log.d(TAG, "Executing headless task")
        // Background task execution logic
    }
}
