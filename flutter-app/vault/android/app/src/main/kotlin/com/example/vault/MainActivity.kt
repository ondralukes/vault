package com.example.vault

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Build
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import androidx.lifecycle.LifecycleRegistry
import androidx.core.content.ContextCompat.getSystemService
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Lifecycle
import androidx.work.ExistingWorkPolicy


class MainActivity: FlutterActivity() {
    val CHANNEL_ID = "VaultNotificationChannel";
    val WORK_NAME = "VaultNotificationWorker";
    private val channel = "com.ondralukes.vault/notification";
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel);
        methodChannel.setMethodCallHandler { call, result ->
                result.notImplemented();
        }
    }

    override fun onDestroy() {
        startNotificationService();
        super.onDestroy();
    }

    override fun onPause() {
        createNotificationChannel();
        startNotificationService();
        super.onPause();
    }

    override fun onResume() {
        val workManager = WorkManager.getInstance();
        workManager.cancelUniqueWork(WORK_NAME);
        showInAppNotification();
        super.onResume();
    }
    private fun startNotificationService(){
        createNotificationChannel();
        val workManager = WorkManager.getInstance();
        val workRequest = OneTimeWorkRequest.Builder(NotificationWorker::class.java).build();
        workManager.enqueueUniqueWork(WORK_NAME, ExistingWorkPolicy.REPLACE,workRequest);
    }
    private fun createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = CHANNEL_ID
            val descriptionText = CHANNEL_ID
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            // Register the channel with the system
            val notificationManager: NotificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showInAppNotification(){
        val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(this,CHANNEL_ID)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("Vault Notification Service")
                .setContentText("Notifications are paused while in app.")
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setOngoing(true);
        notificationManager.notify(1234, builder.build());
    }
}
