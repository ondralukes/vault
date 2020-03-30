import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

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
    var passwordBytes = utf8.encode(password);
    var hash = sha256.convert(passwordBytes);

    final iv = IV.fromSecureRandom(16);
    final key = Key(hash.bytes);
    final aes = Encrypter(AES(
        key,
        mode: AESMode.cbc,
    ));

    final encryptedPrivateKey = aes.encrypt(
        RsaKeyHelper().encodePrivateKeyToPem(keyPair.privateKey),
        iv: iv
    );
    processIndicator.setText('Sending request.');
    Map rsaMap = {
    'public': RsaKeyHelper().encodePublicKeyToPem(keyPair.publicKey),
    'private': encryptedPrivateKey.base64
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
}