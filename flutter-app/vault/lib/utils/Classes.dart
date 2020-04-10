import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:pointycastle/export.dart';
import 'package:vault/utils/ServerAPI.dart';
import 'package:vault/widgets/ChangingText.dart';

import 'CryptoTools.dart';

enum VaultState { Locked, Unlocking, Unlocked }

enum MessageType { Anonymous, Signed, NotSigned, Corrupted }

class User {
  String name;
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> rsa;
}

class Vault {
  static ServerAPI serverAPI;
  Vault(Map map) {
    this.codename = map['codename'];
    this.accessToken = map['accessToken'];
  }

  unlock(Map resp) async {
    this.name = await CryptoTools.decryptData(this.key, resp['name']);
    this.state = VaultState.Unlocked;
    this.messageBase = resp['messagesCount'];
    this.newestIndex = messageBase;
    this.oldestIndex = messageBase;
    newerMessages.clear();
    olderMessages.clear();
  }

  VaultState state = VaultState.Locked;
  String codename;
  String name;
  String accessToken;
  Uint8List key;
  List<String> keys = List<String>();
  int messageBase;
  List<Message> newerMessages = List<Message>();
  List<Message> olderMessages = List<Message>();
  int newestIndex;
  int oldestIndex;

  getMessage(int index) {
    if (index >= messageBase) {
      final i = index - messageBase;
      if (newerMessages.length <= i) return null;
      return newerMessages[i];
    } else {
      final i = messageBase - index - 1;
      if (olderMessages.length <= i) return null;
      return olderMessages[i];
    }
  }

  setMessage(int index, Message message) {
    if (index >= messageBase) {
      newerMessages[index - messageBase] = message;
    } else {
      newerMessages[messageBase - index - 1] = message;
    }
  }

  getMessageCount() {
    return newerMessages.length + olderMessages.length;
  }

  getTotalMessageCount() {
    return newestIndex;
  }

  Future<bool> getOlderMessages() async {
    if (oldestIndex == 0) return false;
    final messages = await serverAPI.getMessages(this, oldestIndex - 8);
    if (messages.length == 0) return false;
    olderMessages.addAll(messages.reversed);
    oldestIndex -= messages.length;
    return true;
  }

  Future<bool> getNewerMessages() async {
    final messages = await serverAPI.getMessages(this, newestIndex);
    if (messages.length == 0) return false;
    newerMessages.addAll(messages.reversed);
    newestIndex += messages.length;
    return true;
  }

  Future<void> sendMessage(String content, MessageType type) async {
    final msg = Message();
    msg.content = content;
    msg.type = type;
    msg.time = DateTime.now().toUtc();
    switch (type) {
      case MessageType.Anonymous:
        msg.sender = null;
        break;
      case MessageType.NotSigned:
        msg.sender = serverAPI.user.name;
        break;
      case MessageType.Signed:
        msg.sender = serverAPI.user.name;
        final textToSign = msg.content +
            'T' +
            msg.time.toUtc().millisecondsSinceEpoch.toString();
        final signatureBytes =
            CryptoTools.sign(serverAPI.user.rsa, utf8.encode(textToSign));
        msg.signature = base64.encode(signatureBytes);
        break;
      case MessageType.Corrupted:
        throw ('Illegal state.');
    }
    final encryptedMessage = await CryptoTools.encryptData(key, msg.toString());
    serverAPI.sendMessage(this, encryptedMessage);
  }

  Future<bool> addMember(String name, ChangingTextState process) async {
    process.setText('Obtaining public key.');
    RSAPublicKey publicKey = await serverAPI.getPublicKey(name);
    if (publicKey == null) {
      process.setText('Failed to obtain public key. Check username.');
      return false;
    }
    process.setText('Encrypting vault key.');
    Uint8List userKeyBytes;
    try {
      AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keypair =
          new AsymmetricKeyPair(publicKey, null);
      userKeyBytes = await CryptoTools.rsaEncryptRaw(keypair, this.key);
    } catch (_) {
      process.setText('Encryption failed.');
      return false;
    }
    final userKeyEncoded = base64.encode(userKeyBytes);
    process.setText('Sending request.');
    Map req = {
      'codename': this.codename,
      'key': {
        'key': userKeyEncoded,
        'user': name
      }
    };
    final resp = await serverAPI.request('vault/member/add', req);
    if(resp.statusCode != 200){
      process.setText('Failed: '+ resp.body);
      return false;
    }
    process.setText('Updating info.');
    await serverAPI.unlockVault(this);
    return true;
  }
}

class Message {
  Message({Map raw}) {
    if (raw == null) {
      type = MessageType.Corrupted;
      content = '[Corrupted]';
      return;
    }
    content = raw['content'];
    if (content.length != raw['length']) {
      type = MessageType.Corrupted;
      content = '[Corrupted]';
      return;
    }
    sender = raw['sender'];
    time =
        new DateTime.fromMillisecondsSinceEpoch(raw['timestamp'], isUtc: true);
    if (raw.containsKey('sender')) {
      if (raw.containsKey('signature')) {
        signature = raw['signature'];
        type = MessageType.Signed;
      } else {
        type = MessageType.NotSigned;
      }
    } else {
      type = MessageType.Anonymous;
    }
  }

  @override
  toString() {
    final map = {
      'sender': sender,
      'content': content,
      'timestamp': time.millisecondsSinceEpoch,
      'signature': signature,
      'length': content.length
    };
    if (type == MessageType.Anonymous) {
      map.remove('sender');
    }
    if (type != MessageType.Signed) {
      map.remove('signature');
    }
    return json.encode(map);
  }

  String content;
  String sender;
  String signature;
  DateTime time;
  MessageType type;
}
