package com.example.vault

import android.content.Context
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.*
import java.lang.Exception
import java.net.ConnectException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLConnection
import java.util.*
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLException
import javax.net.ssl.SSLHandshakeException

/**
 * NotificationWorker
 *
 * This worker requests server every 15 minutes and sends notifications about new messages
 *
 * @constructor Creates new Worker
 * @param context Context
 * @param workerParams WorkerParameters
 */
class NotificationWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    private val c = context;
    val CHANNEL_ID = "VaultNotificationChannel";
    val WORK_NAME = "VaultNotificationWorker";
    val SERVER = "https://www.ondralukes.cz/vault/";
    override fun doWork(): Result {
        val appDir = c.applicationInfo.dataDir + "/app_flutter/"
        val timeFile = File(appDir + "app.open");
        var openTime: Long = 0;
        if (timeFile.exists()) {
            openTime = timeFile.readText().toLong();
        }
        val time = System.currentTimeMillis();
        if (time - openTime < 3000) {
            showNotification("Notifications are paused while in app.");
        } else {
            checkFile();
        }
        return Result.success();
    }

    private fun checkFile() {
        val appDir = c.applicationInfo.dataDir + "/app_flutter/"
        val path = appDir + "vaults.json";
        val file = File(path);

        if (!file.exists()) {
            showNotification("Login to initialize notifications.");
            return;
        }
        checkMessages(file);
    }

    private fun checkMessages(file: File) {

        val vaultsJson = file.readText();
        val vaults = JSONArray(vaultsJson);
        var failedRequests = 0;

        val url = URL(SERVER + "vault/get");
        for (i in 0 until vaults.length()) {
            val v = vaults.get(i) as JSONObject;
            if (!checkVault(v, url, i)) failedRequests++;
        }
        var s = "";
        var reqStr = "";
        if (vaults.length() != 1) s = "s";
        if (failedRequests == 1) reqStr = " 1 request has failed.";
        if (failedRequests > 1) reqStr = " ${failedRequests} requests has failed.";
        showNotification("Notifications set up for ${vaults.length()} vault${s}.${reqStr}");
        file.writeText(vaults.toString());
    }

    private fun checkVault(v: JSONObject, url: URL, i: Int): Boolean {
        var req = JSONObject();
        req.put("codename", v.get("codename"));
        req.put("accessToken", v.get("accessToken"));
        try {
            var conn = url.openConnection() as HttpURLConnection;
            conn.requestMethod = "POST";
            conn.setRequestProperty("Content-Type", "application/json");

            val outputStream = OutputStreamWriter(conn.outputStream);
            outputStream.write(req.toString());
            outputStream.flush();

            if (conn.responseCode != 200) {
                return false;
            }
            val response = StringBuffer();
            conn.inputStream.bufferedReader().use {
                var line = it.readLine();
                while (line != null) {
                    response.append(line);
                    line = it.readLine();
                }
            }

            val serverVault = JSONObject(response.toString());
            val serverMessagesCount = serverVault.getInt("messagesCount");
            if (serverMessagesCount > v.getInt("notifiedMessagesCount")) {
                val count = serverMessagesCount - v.getInt("messagesCount");
                var s = "";
                if (count != 1) s = "s";
                showNotification("You have ${count} new message${s} in [${v.get("codename")}]", i);
                v.put("notifiedMessagesCount", serverMessagesCount);
            }
            conn.disconnect();
        } catch (e: ConnectException) {
            return false;
        } catch (e: SSLException) {
            return false;
        } catch (e: SSLHandshakeException) {
            return false;
        } catch (e: IOException) {
            return false;
        }
        return true;
    }

    private fun showNotification(content: String, id: Int = -1) {
        val notificationManager = NotificationManagerCompat.from(c);
        val builder = NotificationCompat.Builder(c, CHANNEL_ID)
                .setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("Vault Notification Service")
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setOnlyAlertOnce(id == -1)
                .setOngoing(id == -1);
        notificationManager.notify(id, builder.build());
    }
}