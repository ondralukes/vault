package com.vault.crypto;

import android.telecom.Call;
import android.util.Base64;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import org.json.JSONObject;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;

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
}
