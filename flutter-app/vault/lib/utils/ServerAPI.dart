import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';

import 'package:vault/widgets/ChangingText.dart';
import 'package:vault/utils/CryptoTools.dart';
import 'package:vault/utils/rsa_pem.dart';

import 'package:http/http.dart' as Http;

import 'Classes.dart';

class ServerAPI {
  final String url;
  final session = new Session();
  var context;
  var connectionLost = false;
  User user;
  ServerAPI(this.url);

  setContext(context) {
    if (ModalRoute.of(context).isCurrent) {
      this.context = context;
    }
  }

  Future<bool> signUp(
      String name, String password, ChangingTextState processIndicator) async {
    processIndicator.setText('Generaing keypair. This might take a while.');
    var keyPair = await CryptoTools.generateRSA();

    processIndicator.setText('Encrypting keypair.');

    final encryptedPrivateKey = await CryptoTools.encryptData(
        CryptoTools.getKey(password),
        RsaKeyHelper().encodePrivateKeyToPem(keyPair.privateKey));

    processIndicator.setText('Sending request.');
    Map rsaMap = {
      'public': RsaKeyHelper().encodePublicKeyToPem(keyPair.publicKey),
      'private': encryptedPrivateKey
    };

    Map req = {'name': name, 'rsa': rsaMap};

    Map<String, String> headers = {'Content-Type': 'application/json'};

    Http.Response resp;
    try {
      resp = await Http.post(url + 'user/create',
          headers: headers, body: jsonEncode(req));
    } catch (e) {
      processIndicator.setText('Failed to connect.');
      return false;
    }

    if (resp.statusCode != 200) {
      processIndicator.setText('Request failed: ' + resp.body);
      return false;
    }
    user = new User();
    this.user.name = name;
    this.user.rsa = keyPair;
    return true;
  }

  Future<bool> signIn(
      String name, String password, ChangingTextState processIndicator) async {
    processIndicator.setText('Requesting server for access.');

    Map req = {
      'name': name,
    };

    Http.Response tokenResp;

    try {
      tokenResp = await session.post(url + 'token', jsonEncode(req));
    } catch (e) {
      processIndicator.setText('Failed to connect.');
      return false;
    }

    if (tokenResp.statusCode != 200) {
      processIndicator.setText('Request failed: ' + tokenResp.body);
      return false;
    }

    final tokenJson = jsonDecode(tokenResp.body);

    processIndicator.setText('Decrypting keypair.');
    try {
      tokenJson['user']['rsa']['private'] = await CryptoTools.decryptData(
          CryptoTools.getKey(password), tokenJson['user']['rsa']['private']);
    } catch (err) {
      processIndicator.setText('Failed to decrypt keypair. Wrong password?');
      return false;
    }

    final publicKey = RsaKeyHelper()
        .parsePublicKeyFromPem(tokenJson['user']['rsa']['public']);
    final privateKey = RsaKeyHelper()
        .parsePrivateKeyFromPem(tokenJson['user']['rsa']['private']);

    user = new User();
    this.user.name = name;
    this.user.rsa = new AsymmetricKeyPair(publicKey, privateKey);

    processIndicator.setText('Signing.');
    final signedToken =
        CryptoTools.sign(this.user.rsa, hex.decode(tokenJson['token']));

    processIndicator.setText('Sending signature');
    req = {
      'signedToken': hex.encode(signedToken),
    };

    Http.Response authResp;
    try {
      authResp = await session.post(url + 'verifyToken', jsonEncode(req));
    } catch (e) {
      processIndicator.setText('Failed to connect.');
      return false;
    }

    if (authResp.statusCode != 200) {
      processIndicator.setText('Request failed: ' + authResp.body);
      return false;
    }
    return true;
  }

  Future<Map> getUserData() async {
    final resp = await request('user/get/private', Map());
    if (resp == null) {
      return Map();
    }
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return Map();
  }

  Future<bool> logOut() async {
    user = null;
    return true;
  }

  Future<bool> unlockVault(Vault vault) async {
    vault.state = VaultState.Unlocking;

    final data = {
      'codename': vault.codename,
      'accessToken': vault.accessToken,
    };

    final resp = await requestUnsafe('vault/get', data);
    if (resp == null) {
      vault.state = VaultState.Locked;
      return false;
    }

    if (resp.statusCode != 200) {
      vault.state = VaultState.Locked;
      return false;
    }

    final respObj = json.decode(resp.body);

    String encryptedKey;
    vault.keys.clear();
    respObj['keys'].forEach((key) {
      vault.keys.add(key['user']);
      if (key['user'] == this.user.name) {
        encryptedKey = key['key'];
      }
    });

    vault.key = await CryptoTools.rsaDecryptRaw(
        this.user.rsa, base64.decode(encryptedKey));

    vault.unlock(respObj);

    return true;
  }

  Future<List> getMessages(Vault vault, int offset) async {
    var count = 8;
    if (offset < 0) {
      count += offset;
      offset = 0;
    }

    Map data = {
      'accessToken': vault.accessToken,
      'codename': vault.codename,
      'offset': offset,
      'count': count
    };

    final resp = await requestUnsafe('message/get', data);
    if (resp == null) {
      return List<Message>();
    }
    if (resp.statusCode != 200) {
      return List<Message>();
    }
    final result = List<Message>();
    final encryptedMessages = json.decode(resp.body);

    for (var i = 0; i < encryptedMessages.length; i++) {
      final encrypted = encryptedMessages[i];
      try {
        final decrypted = await CryptoTools.decryptData(vault.key, encrypted);
        final raw = json.decode(decrypted);
        Message msg = Message(raw: raw);
        if (msg.type == MessageType.Signed) {
          final valid = await verifySignature(msg);
          if (!valid) {
            msg = Message();
          }
        }
        result.add(msg);
      } catch (_) {
        result.add(Message());
      }
    }
    return result;
  }

  Future<void> sendMessage(Vault vault, String encryptedMessage) async {
    final req = {
      'codename': vault.codename,
      'accessToken': vault.accessToken,
      'message': encryptedMessage
    };
    final resp = await requestUnsafe('message/send', req);
    if (resp.statusCode != 200) {
      throw ('Server returned error code.');
    }
  }

  Future<bool> verifySignature(Message message) async {
    RSAPublicKey publicKey = await getPublicKey(message.sender);
    if (publicKey == null) {
      return false;
    }
    final stringToSign =
        message.content + 'T' + message.time.millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(stringToSign);
    final signatureBytes = base64.decode(message.signature);
    return CryptoTools.verify(publicKey, bytes, signatureBytes);
  }

  Future<bool> createVault(
      String codename, String name, ChangingTextState processIndicator) async {
    processIndicator.setText('Generating key');
    final random = Random.secure();
    final key = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }

    processIndicator.setText('Encrypting key');
    final encryptedName = await CryptoTools.encryptData(key, name);
    final encryptedKey = await CryptoTools.rsaEncryptRaw(user.rsa, key);
    Map req = {
      'codename': codename,
      'name': encryptedName,
      'keys': [
        {'user': user.name, 'key': base64.encode(encryptedKey)}
      ]
    };

    processIndicator.setText('Sending request');
    final resp = await request('vault/create', req);
    if (resp == null) {
      processIndicator.setText('Failed to connect');
      return false;
    }
    if (resp.statusCode != 200) {
      processIndicator.setText('Failed:' + resp.body);
      return false;
    }
    processIndicator.setText('Success');
    return true;
  }

  Future<RSAPublicKey> getPublicKey(String name) async {
    Map req = {'name': name};
    final resp = await requestUnsafe('user/get/public', req);
    if (resp == null) return null;
    if (resp.statusCode != 200) return null;
    final respJson = json.decode(resp.body);
    return RsaKeyHelper().parsePublicKeyFromPem(respJson['rsa']['public']);
  }

  Future<Http.Response> request(String relativeUrl, Map data) async {
    Map req = {
      'name': this.user.name,
    };

    Http.Response tokenResp;
    while (true) {
      try {
        tokenResp = await session.post(url + 'token', jsonEncode(req));
      } catch (e) {
        if (!connectionLost) alert("Lost connection to server!");
        connectionLost = true;
        continue;
      }
      break;
    }
    if (connectionLost) {
      Navigator.of(context).pop();
    }
    connectionLost = false;

    if (tokenResp.statusCode != 200) {
      return tokenResp;
    }

    final tokenJson = jsonDecode(tokenResp.body);

    final signedToken =
        CryptoTools.sign(this.user.rsa, hex.decode(tokenJson['token']));

    data['signedToken'] = hex.encode(signedToken);

    return await requestUnsafe(relativeUrl, data);
  }

  Future<Http.Response> requestUnsafe(String relativeUrl, Map data) async {
    Http.Response authResp;
    while (true) {
      try {
        authResp = await session.post(url + relativeUrl, jsonEncode(data));
      } catch (e) {
        if (!connectionLost) alert("Lost connection to server!");
        connectionLost = true;
        continue;
      }
      break;
    }
    if (connectionLost) {
      Navigator.of(context).pop();
    }
    connectionLost = false;
    if (authResp.statusCode != 200) {
      return authResp;
    }
    return authResp;
  }

  alert(message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
              title: Text('Connection lost!'),
              content: Text('Reconnecting...'));
        });
  }
}

class Session {
  Map<String, String> headers = {'Content-Type': 'application/json'};

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
