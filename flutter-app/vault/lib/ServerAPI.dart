import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as Encrypt;
import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

import 'package:vault/ChangingText.dart';
import 'package:vault/CryptoTools.dart';
import 'package:vault/rsa_pem.dart';

import 'package:http/http.dart' as Http;

import 'Classes.dart';

class ServerAPI{
  final String url;
  final session = new Session();
  User user;
  ServerAPI(this.url);

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
    user = new User();
    this.user.name = name;
    this.user.rsa = keyPair;
    return true;
  }

  Future<bool> signIn(String name, String password, ChangingTextState processIndicator) async {
    processIndicator.setText('Requesting server for access.');

    Map req = {
      'name': name,
    };

    Http.Response tokenResp = await session.post(
        url + '/token',
        jsonEncode(req)
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

    Http.Response authResp = await session.post(
        url + '/verifyToken',
        jsonEncode(req)
    );

    if(authResp.statusCode != 200){
      processIndicator.setText('Request failed: ' + authResp.body);
      return false;
    }
    user = new User();
    this.user.name = name;
    this.user.rsa = new AsymmetricKeyPair(publicKey, privateKey);
    return true;
  }

  Future<Map> getUserData() async{
    final resp = await request('/user/get/private', Map());
    if(resp.statusCode == 200){
      return jsonDecode(resp.body);
    }
    return Map();
  }

  Future<bool> logOut() async {
    user = null;
    return true;
  }

  Future<Http.Response> request(String relativeUrl, Map data,) async {
    Map req = {
      'name': this.user.name,
    };

    Http.Response tokenResp = await session.post(
        url + '/token',
        jsonEncode(req)
    );

    if(tokenResp.statusCode != 200){
      return tokenResp;
    }

    final tokenJson = jsonDecode(tokenResp.body);


    final signer = Encrypt.Signer(
        Encrypt.RSASigner(
            Encrypt.RSASignDigest.SHA256,
            publicKey: this.user.rsa.publicKey,
            privateKey: this.user.rsa.privateKey
        )
    );

    final signedToken = signer.signBytes(hex.decode(tokenJson['token']));

    data['signedToken'] = hex.encode(signedToken.bytes);

    Http.Response authResp = await session.post(
        url + relativeUrl,
        jsonEncode(data)
    );

    if(authResp.statusCode != 200){
      return authResp;
    }
    return authResp;
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

class Session {
  Map<String, String> headers = {
    'Content-Type': 'application/json'
  };

  Future<Http.Response> post(String url, dynamic data) async {
    Http.Response response = await Http.post(url, body: data, headers: headers);
    updateCookie(response);
    return response;
  }

  void updateCookie(Http.Response response) {
    String rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
      (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }
}