package com.example.vault

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * BroadcastReceiver. Starts notification WorkRequest omn boot.
 * @constructor Creates an BroadcastReceiver.
 */
class BootReceiver : BroadcastReceiver(){
    val CHANNEL_ID = "VaultNotificationChannel";
    val WORK_NAME = "VaultNotificationWorker";
    override fun onReceive(p0: Context?, p1: Intent?) {
        startNotificationService();

    }

    private fun startNotificationService(){
        val workManager = WorkManager.getInstance();
        val workRequest =
                PeriodicWorkRequest.Builder(NotificationWorker::class.java, 15, TimeUnit.MINUTES)
                        .build();

        workManager.enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.REPLACE,workRequest);
    }
}