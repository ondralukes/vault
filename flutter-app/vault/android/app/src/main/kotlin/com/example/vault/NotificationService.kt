package com.example.vault

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat.getSystemService
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import android.os.Handler
import android.util.Log
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import android.os.HandlerThread
import android.widget.Toast
import java.util.*


class NotificationService : Service() {
    val CHANNEL_ID = "VaultNotificationChannel";
    val timer = Timer();

    override fun onBind(p0: Intent?): IBinder? {
        return null;
    }

    override fun onCreate() {
        setTimer();
        super.onCreate()
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY;
    }

    override fun stopService(name: Intent?): Boolean {
        return super.stopService(name)
    }

    override fun onDestroy() {
        timer.cancel();
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(this@NotificationService,CHANNEL_ID)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("Vault Notification Service")
                .setContentText("Notifications are paused while in app.")
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setOngoing(true);
        notificationManager.notify(1234, builder.build());
        super.onDestroy();
    }

    fun setTimer(){
        timer.purge();
        var i = 0;
        timer.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val builder = NotificationCompat.Builder(this@NotificationService,CHANNEL_ID)
                        .setSmallIcon(R.drawable.notification_icon)
                        .setContentTitle("Vault Notification Service")
                        .setContentText("Running for $i seconds.")
                        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                        .setOngoing(true);
                notificationManager.notify(1234, builder.build());
                i++;
            }
        }, 0,1000);
    }
}