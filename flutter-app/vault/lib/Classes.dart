import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:pointycastle/export.dart';
import 'package:vault/ServerAPI.dart';

import 'CryptoTools.dart';

enum VaultState{
  Locked,
  Unlocking,
  Unlocked
}

enum MessageType{
  Anonymous,
  Signed,
  NotSigned,
  Corrupted
}

class User {
  String name;
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> rsa;
}

class Vault {
  static ServerAPI serverAPI;
  Vault(Map map){
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
  int messageBase;
  List<Message> newerMessages = List<Message>();
  List<Message> olderMessages = List<Message>();
  int newestIndex;
  int oldestIndex;

  getMessage(int index){
    if(index >= messageBase){
      final i = index - messageBase;
      if(newerMessages.length <= i) return null;
      return newerMessages[i];
    } else {
      final i = messageBase - index - 1;
      if(olderMessages.length <= i) return null;
      return olderMessages[i];
    }
  }

  setMessage(int index, Message message){
    if(index >= messageBase){
      newerMessages[index - messageBase] = message;
    } else {
      newerMessages[messageBase - index - 1] = message;
    }
  }

  getMessageCount(){
    return newerMessages.length + olderMessages.length;
  }

  Future<bool> getOlderMessages() async {
    if(oldestIndex == 0) return false;
    final messages = await serverAPI.getMessages(this, oldestIndex - 32);
    if(messages.length == 0) return false;
    olderMessages.addAll(messages.reversed);
    oldestIndex -= messages.length;
    return true;
  }
}

class Message {
  Message({Map raw}){
    if(raw == null){
      type = MessageType.Corrupted;
      content = '[Corrupted]';
      return;
    }
    content = raw['content'];
    sender = raw['sender'];
    time = new DateTime.fromMillisecondsSinceEpoch(raw['timestamp'], isUtc: true);
    if(raw.containsKey('sender')){
      if(raw.containsKey('signature')){
        type = MessageType.Signed;
      } else {
        type = MessageType.NotSigned;
      }
    } else {
      type = MessageType.Anonymous;
    }
  }
  String content;
  String sender;
  DateTime time;
  MessageType type;
}