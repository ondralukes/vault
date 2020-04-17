package com.example.vault

import android.content.Context
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.*
import java.util.concurrent.TimeUnit

class NotificationWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    private val c = context;
    val CHANNEL_ID = "VaultNotificationChannel";
    val WORK_NAME = "VaultNotificationWorker";
    override fun doWork(): Result {
        //TODO: Check for messages
        val notificationManager = NotificationManagerCompat.from(c);
        val builder = NotificationCompat.Builder(c,CHANNEL_ID)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("Vault Notification Service")
                .setContentText("T:" + System.currentTimeMillis())
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setOngoing(true);
        notificationManager.notify(1234, builder.build());
        val workManager = WorkManager.getInstance();
        val workRequest = OneTimeWorkRequest.Builder(NotificationWorker::class.java)
                .setInitialDelay(1, TimeUnit.SECONDS)
                .build();
        workManager.enqueueUniqueWork(WORK_NAME,ExistingWorkPolicy.REPLACE, workRequest);
        return Result.success();
    }

}