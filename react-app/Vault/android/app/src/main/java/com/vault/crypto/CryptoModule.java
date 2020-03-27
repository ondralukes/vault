package com.vault.crypto;

import android.util.Base64;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import java.nio.charset.StandardCharsets;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Arrays;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class CryptoModule extends ReactContextBaseJavaModule {
    private static final char[] HEX_ARRAY = "0123456789abcdef".toCharArray();

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
        private Callback cb;
        private ReadableMap rsaKey;
        private String password;
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

                String encodedEncrypted = encryptData(keyBytes, rsaKey.getString("private"));
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

    @ReactMethod
    public void decryptRSA(ReadableMap rsaKey, String password, Callback cb){
        DecryptRSA g = new DecryptRSA(rsaKey, password, cb);
        new Thread(g).start();
    }
    class DecryptRSA implements Runnable {
        private Callback cb;
        private ReadableMap rsaKey;
        private String password;
        DecryptRSA(ReadableMap rsaKey, String password, Callback cb){
            this.rsaKey = rsaKey;
            this.password = password;
            this.cb = cb;
        }
        @Override
        public void run() {
            try {
                MessageDigest key = MessageDigest.getInstance("SHA-256");
                byte[] keyBytes = key.digest(password.getBytes(StandardCharsets.UTF_8));

                String encodedDecrypted = decryptData(keyBytes,rsaKey.getString("private"));
                WritableMap result = new WritableNativeMap();
                result.putString("public", rsaKey.getString("public"));
                result.putString("private", encodedDecrypted);
                cb.invoke(result);
            } catch (Exception e){
                WritableMap result = new WritableNativeMap();
                result.putString("err", e.getMessage());
                cb.invoke(result);
            }
        }
    }

    @ReactMethod
    public void signToken(ReadableMap rsaKey, String token, Callback cb){
        SignToken g = new SignToken(rsaKey, token, cb);
        new Thread(g).start();
    }
    class SignToken implements Runnable {
        private Callback cb;
        private ReadableMap rsaKey;
        private String token;
        SignToken(ReadableMap rsaKey, String token, Callback cb){
            this.rsaKey = rsaKey;
            this.token = token;
            this.cb = cb;
        }
        @Override
        public void run() {
            try {
                String privateKeyStr = rsaKey.getString("private");
                privateKeyStr = privateKeyStr.replace("-----BEGIN RSA PRIVATE KEY-----\n", "");
                privateKeyStr = privateKeyStr.replace("-----END RSA PRIVATE KEY-----\n", "");

                byte[] privateKeyBytes = Base64.decode(privateKeyStr, Base64.DEFAULT);

                PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(privateKeyBytes);

                KeyFactory keyFactory = KeyFactory.getInstance("RSA");
                PrivateKey privateKey = keyFactory.generatePrivate(keySpec);

                Signature signature = Signature.getInstance("SHA256withRSA");
                signature.initSign(privateKey);

                byte[] tokenBytes = hexToBytes(token);

                signature.update(tokenBytes);

                byte[] bytes = signature.sign();

                WritableMap result = new WritableNativeMap();
                result.putString("signedToken", bytesToHex(bytes));
                cb.invoke(result);
            } catch (Exception e) {
                WritableMap result = new WritableNativeMap();
                result.putString("err", e.getMessage());
                cb.invoke(result);
            }
        }
    }

    private static String encryptData(byte[] keyBytes, String data) throws NoSuchAlgorithmException, NoSuchPaddingException, InvalidAlgorithmParameterException, InvalidKeyException, BadPaddingException, IllegalBlockSizeException {
        Cipher cipher = Cipher.getInstance("AES/CBC/NoPadding");

        SecureRandom rnd = SecureRandom.getInstance("SHA1PRNG");
        byte[] iv = new byte[cipher.getBlockSize()];
        rnd.nextBytes(iv);

        IvParameterSpec ivParams = new IvParameterSpec(iv);

        SecretKeySpec keySpec = new SecretKeySpec(keyBytes, "AES");

        byte[] dataBytes = data.getBytes(StandardCharsets.UTF_8);
        int paddingLength = 16 - (dataBytes.length % 16);
        if(paddingLength == 16) paddingLength = 0;

        byte[] padding = new byte[paddingLength];
        rnd.nextBytes(padding);
        dataBytes = concat(padding, dataBytes);

        cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivParams);

        byte[] encrypted = cipher.doFinal(dataBytes);

        byte[] result = iv;
        byte[] paddingLengthBuffer = new byte[1];
        paddingLengthBuffer[0] = (byte) paddingLength;
        result = concat(result, paddingLengthBuffer);
        result = concat(result, encrypted);

        String encodedEncrypted = Base64.encodeToString(result, Base64.DEFAULT);
        return encodedEncrypted;
    }
    private static String decryptData(byte[] keyBytes, String data) throws NoSuchAlgorithmException, NoSuchPaddingException, InvalidAlgorithmParameterException, InvalidKeyException, BadPaddingException, IllegalBlockSizeException {
        Cipher cipher = Cipher.getInstance("AES/CBC/NoPadding");

        byte[] dataBytes = Base64.decode(data, Base64.DEFAULT);
        byte[] iv = Arrays.copyOfRange(dataBytes, 0, 16);
        int paddingLength = dataBytes[16] & 0xff;
        byte[] messageDataBytes = Arrays.copyOfRange(dataBytes, 17, dataBytes.length);

        IvParameterSpec ivParams = new IvParameterSpec(iv);

        SecretKeySpec keySpec = new SecretKeySpec(keyBytes, "AES");

        cipher.init(Cipher.DECRYPT_MODE, keySpec, ivParams);

        byte[] decrypted = cipher.doFinal(messageDataBytes);

        decrypted = Arrays.copyOfRange(decrypted, paddingLength, decrypted.length);
        String encodedDecrypted = new String(decrypted, StandardCharsets.UTF_8);
        return encodedDecrypted;
    }
    private static byte[] concat(byte[] a, byte[] b){
        byte[] c = new byte[a.length + b.length];
        System.arraycopy(a, 0, c, 0, a.length);
        System.arraycopy(b, 0, c, a.length, b.length);
        return c;
    }
    private static byte[] hexToBytes(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                    + Character.digit(s.charAt(i+1), 16));
        }
        return data;
    }
    private static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for (int j = 0; j < bytes.length; j++) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = HEX_ARRAY[v >>> 4];
            hexChars[j * 2 + 1] = HEX_ARRAY[v & 0x0F];
        }
        return new String(hexChars);
    }
}
