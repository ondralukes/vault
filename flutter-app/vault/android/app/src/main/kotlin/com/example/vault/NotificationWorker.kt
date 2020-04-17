package com.example.vault

import android.content.Context
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

class NotificationWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    private val c = context;
    val CHANNEL_ID = "VaultNotificationChannel";
    val WORK_NAME = "VaultNotificationWorker";
    override fun doWork(): Result {
        val path = c.applicationInfo.dataDir + "/app_flutter/vaults.json";
        val file = File(path);
        if(!file.exists()){
            showNotification("Login to initialize notifications.");
        } else {
            val vaultsJson = file.readText();
            val vaults = JSONArray(vaultsJson);
            if(vaults.length() == 1){
                showNotification("Notifications set up for 1 vault.");
            } else {
                showNotification("Notifications set up for " + vaults.length() + " vaults.");
            };
        }
        //TODO: Check for messages
        val workManager = WorkManager.getInstance();
        val workRequest = OneTimeWorkRequest.Builder(NotificationWorker::class.java)
                .setInitialDelay(1, TimeUnit.SECONDS)
                .build();
        workManager.enqueueUniqueWork(WORK_NAME,ExistingWorkPolicy.REPLACE, workRequest);
        return Result.success();
    }

    private fun showNotification(content: String){
        val notificationManager = NotificationManagerCompat.from(c);
        val builder = NotificationCompat.Builder(c,CHANNEL_ID)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("Vault Notification Service")
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setOnlyAlertOnce(true)
                .setOngoing(true);
        notificationManager.notify(1234, builder.build());
    }
}