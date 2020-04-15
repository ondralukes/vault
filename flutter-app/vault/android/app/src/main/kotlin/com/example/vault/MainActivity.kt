package com.example.vault

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import android.util.Log


class MainActivity: FlutterActivity() {
    private val channel = "com.ondralukes.vault/notification";
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel);
        methodChannel.setMethodCallHandler { call, result ->
             if(call.method == "stop"){
                Intent(this, NotificationService::class.java).also { i ->
                    stopService(i);
                };
                result.success(null);
            } else {
                result.notImplemented();
            }
        }
    }

    override fun onDestroy() {
        Intent(this, NotificationService::class.java).also { i ->
            startService(i);
        };
        super.onDestroy()
    }

    override fun onPause() {
        Intent(this, NotificationService::class.java).also { i ->
            startService(i);
        };
        super.onPause()
    }

    override fun onResume() {
        Intent(this, NotificationService::class.java).also { i ->
            stopService(i);
        };
        super.onResume()
    }
}
