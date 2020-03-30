import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as Encrypt;
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';

import 'package:vault/ChangingText.dart';
import 'package:vault/CryptoTools.dart';
import 'package:vault/rsa_pem.dart';

import 'package:http/http.dart' as Http;

class ServerAPI{
  String url;
  ServerAPI(String url){
    this.url = url;
  }

  Future<bool> signUp(String name, String password, ChangingTextState processIndicator) async {
    processIndicator.setText('Generaing keypair. This might take a while.');
    var keyPair = await CryptoTools.generateRSA();

    processIndicator.setText('Encrypting keypair.');

    final encryptedPrivateKey = encryptData(
        getKey(password),
        RsaKeyHelper().encodePrivateKeyToPem(keyPair.privateKey)
    );

    processIndicator.setText('Sending request.');
    Map rsaMap = {
    'public': RsaKeyHelper().encodePublicKeyToPem(keyPair.publicKey),
    'private': encryptedPrivateKey
  };

    Map req = {
      'name': name,
      'rsa': rsaMap
    };

    Map<String, String> headers = {
      'Content-Type': 'application/json'
    };

    Http.Response resp = await Http.post(
    url + '/user/create',
    headers: headers,
    body: jsonEncode(req)
    );

    if(resp.statusCode != 200){
      processIndicator.setText('Request failed: ' + resp.body);
      return false;
    }
    return true;
  }

  Future<bool> signIn(String name, String password, ChangingTextState processIndicator) async {
    processIndicator.setText('Requesting server for access.');

    Map<String, String> headers = {
      'Content-Type': 'application/json'
    };

    Map req = {
      'name': name,
    };

    Http.Response tokenResp = await Http.post(
        url + '/token',
        headers: headers,
        body: jsonEncode(req)
    );

    if(tokenResp.statusCode != 200){
      processIndicator.setText('Request failed: ' + tokenResp.body);
      return false;
    }

    final tokenJson = jsonDecode(tokenResp.body);

    processIndicator.setText('Decrypting keypair.');
    try {
      tokenJson['user']['rsa']['private'] =
          decryptData(getKey(password), tokenJson['user']['rsa']['private']);
    } catch (err){
      processIndicator.setText('Failed to decrypt keypair. Wrong password?');
      return false;
    }

    final publicKey = RsaKeyHelper().parsePublicKeyFromPem(tokenJson['user']['rsa']['public']);
    final privateKey = RsaKeyHelper().parsePrivateKeyFromPem(tokenJson['user']['rsa']['private']);

    final signer = Encrypt.Signer(
      Encrypt.RSASigner(
        Encrypt.RSASignDigest.SHA256,
        publicKey: publicKey,
        privateKey: privateKey
      )
    );

    processIndicator.setText('Signing.');
    final signedToken = signer.signBytes(hex.decode(tokenJson['token']));

    processIndicator.setText('Sending signature');
    req = {
      'signedToken': hex.encode(signedToken.bytes),
    };

    Http.Response authResp = await Http.post(
        url + '/token',
        headers: headers,
        body: jsonEncode(req)
    );

    if(tokenResp.statusCode != 200){
      processIndicator.setText('Request failed: ' + authResp.body);
      return false;
    }
    return true;
  }
  Uint8List getKey(String password){
    var passwordBytes = utf8.encode(password);
    var hash = sha256.convert(passwordBytes);
    return hash.bytes;
  }
  String encryptData(Uint8List keyBytes, String data){
    final dataBytes = utf8.encode(data);

    var paddingLength = 16 - (data.length % 16);
    if(paddingLength == 16) paddingLength = 0;
    final rand = Random.secure();
    final paddingBytes = List<int>.generate(paddingLength, (i) => rand.nextInt(256));

    final bytesToEncrypt = paddingBytes + dataBytes;

    final iv = Encrypt.IV.fromSecureRandom(16);
    final key = Encrypt.Key(keyBytes);
    final aes = Encrypt.Encrypter(Encrypt.AES(
        key,
        mode: Encrypt.AESMode.cbc,
        padding: null
    ));

    final encrypted = aes.encrypt(
        String.fromCharCodes(bytesToEncrypt),
        iv: iv
    );
    final finalBytes = iv.bytes + [paddingLength] + encrypted.bytes;
    return base64.encode(finalBytes);
  }
  String decryptData(Uint8List keyBytes, String data){
    final dataBytes = base64.decode(data);

    final ivBytes = dataBytes.sublist(0,16);
    final paddingLength = dataBytes[16];
    final bytesToDecrypt = dataBytes.sublist(17);

    final iv = Encrypt.IV(ivBytes);
    final key = Encrypt.Key(keyBytes);
    final aes = Encrypt.Encrypter(Encrypt.AES(
      key,
      mode: Encrypt.AESMode.cbc,
      padding: null
    ));

    final decrypted = aes.decrypt(
        Encrypt.Encrypted(bytesToDecrypt),
        iv: iv
    );
    final decryptedBytes = decrypted.codeUnits;
    final finalBytes = decryptedBytes.sublist(paddingLength);
    return utf8.decode(finalBytes);
  }
}