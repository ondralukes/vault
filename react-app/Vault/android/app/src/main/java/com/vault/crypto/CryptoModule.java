package com.vault.crypto;

import android.telecom.Call;
import android.util.Base64;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableNativeMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.PublicKey;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

public class CryptoModule extends ReactContextBaseJavaModule {
    public CryptoModule(ReactApplicationContext reactContext){
        super(reactContext);
    }

    @NonNull
    @Override
    public String getName() {
        return "Crypto";
    }

    @ReactMethod
    public void generateRSA(Callback cb){
        GenerateRSA g = new GenerateRSA(cb);
        new Thread(g).start();
    }
    class GenerateRSA implements Runnable {
        Callback cb;
        GenerateRSA(Callback cb){
            this.cb = cb;
        }
        @Override
        public void run() {
            try {
                KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
                generator.initialize(2048);
                KeyPair key = generator.generateKeyPair();

                PrivateKey privateKey = key.getPrivate();
                PublicKey publicKey = key.getPublic();

                String privateKeyStr = "-----BEGIN RSA PRIVATE KEY-----\n";
                privateKeyStr += Base64.encodeToString(privateKey.getEncoded(), Base64.DEFAULT);
                privateKeyStr += "\n-----END RSA PRIVATE KEY-----\n";

                String publicKeyStr = "-----BEGIN PUBLIC KEY-----\n";
                publicKeyStr += Base64.encodeToString(publicKey.getEncoded(), Base64.DEFAULT);
                publicKeyStr += "\n-----END PUBLIC KEY-----\n";

                WritableMap result = new WritableNativeMap();
                result.putString("private", privateKeyStr);
                result.putString("public", publicKeyStr);
                cb.invoke(result);
            } catch (Exception e){
                WritableMap result = new WritableNativeMap();
                result.putString("err", e.getMessage());
                cb.invoke(result);
            }
        }
    }

    @ReactMethod
    public void encryptRSA(ReadableMap rsaKey, String password, Callback cb){
        EncryptRSA g = new EncryptRSA(rsaKey, password, cb);
        new Thread(g).start();
    }
    class EncryptRSA implements Runnable {
        Callback cb;
        ReadableMap rsaKey;
        String password;
        EncryptRSA(ReadableMap rsaKey, String password, Callback cb){
            this.rsaKey = rsaKey;
            this.password = password;
            this.cb = cb;
        }
        @Override
        public void run() {
            try {
                MessageDigest key = MessageDigest.getInstance("SHA-256");
                byte[] keyBytes = key.digest(password.getBytes(StandardCharsets.UTF_8));

                SecretKeySpec keySpec = new SecretKeySpec(keyBytes, "AES");

                String privateKey = rsaKey.getString("private");
                byte[] privateKeyBytes = privateKey.getBytes(StandardCharsets.UTF_8);

                Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
                cipher.init(Cipher.ENCRYPT_MODE, keySpec);

                byte[] encrypted = cipher.doFinal(privateKeyBytes);
                String encodedEncrypted = Base64.encodeToString(encrypted, Base64.DEFAULT);
                WritableMap result = new WritableNativeMap();
                result.putString("public", rsaKey.getString("public"));
                result.putString("private", encodedEncrypted);
                cb.invoke(result);
            } catch (Exception e){
                WritableMap result = new WritableNativeMap();
                result.putString("err", e.getMessage());
                cb.invoke(result);
            }
        }
    }
}
