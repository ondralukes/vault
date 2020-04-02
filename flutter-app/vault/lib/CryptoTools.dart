import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as Encrypt;

class CryptoTools{
  static Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> generateRSA() async {
    return await compute(CryptoTools.generateRSAEntryPoint, null);
  }
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAEntryPoint(int _){
    final rnd = FortunaRandom();

    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    rnd.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGen = RSAKeyGenerator()
        ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        rnd
      )
    );

    final pair = keyGen.generateKeyPair();

    final privateKey = pair.privateKey as RSAPrivateKey;
    final publicKey = pair.publicKey as RSAPublicKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
  }
  static Uint8List getKey(String password){
    var passwordBytes = utf8.encode(password);
    var hash = sha256.convert(passwordBytes);
    return hash.bytes;
  }

  static Future<String> encryptData(Uint8List keyBytes, String data) async {
    return base64.encode(await encryptDataRaw(keyBytes, utf8.encode(data)));
  }
  static Future<Uint8List> encryptDataRaw(Uint8List keyBytes, Uint8List data) async {
    return await compute(
        CryptoTools.encryptDataEntryPoint,
        {
          'keyBytes': keyBytes,
          'data': data
        }
    );
  }
  static Uint8List encryptDataEntryPoint(Map args){
    final keyBytes = args['keyBytes'];
    final Uint8List data = args['data'];

    var paddingLength = 16 - (data.length % 16);
    if(paddingLength == 16) paddingLength = 0;
    final rand = Random.secure();
    final paddingBytes = List<int>.generate(paddingLength, (i) => rand.nextInt(256));

    final bytesToEncrypt = paddingBytes + data;

    final iv = Encrypt.IV.fromSecureRandom(16);
    final key = Encrypt.Key(keyBytes);
    final aes = Encrypt.Encrypter(Encrypt.AES(
        key,
        mode: Encrypt.AESMode.cbc,
        padding: null
    ));

    final encrypted = aes.encryptBytes(
        bytesToEncrypt,
        iv: iv
    );
    final finalBytes = iv.bytes + [paddingLength] + encrypted.bytes;
    return finalBytes;
  }

  static Future<String> decryptData(Uint8List keyBytes, String data) async {
    return utf8.decode(await decryptDataRaw(keyBytes, base64.decode(data)));
  }
  static Future<Uint8List> decryptDataRaw(Uint8List keyBytes, Uint8List data) async {
    return await compute(
        CryptoTools.decryptDataEntryPoint,
        {
          'keyBytes': keyBytes,
          'data': data
        }
    );
  }
  static Uint8List decryptDataEntryPoint(Map args){
    final keyBytes = args['keyBytes'];
    final Uint8List data = args['data'];

    final ivBytes = data.sublist(0,16);
    final paddingLength = data[16];
    final bytesToDecrypt = data.sublist(17);

    final iv = Encrypt.IV(ivBytes);
    final key = Encrypt.Key(keyBytes);
    final aes = Encrypt.Encrypter(Encrypt.AES(
        key,
        mode: Encrypt.AESMode.cbc,
        padding: null
    ));

    final decryptedBytes = aes.decryptBytes(
        Encrypt.Encrypted(bytesToDecrypt),
        iv: iv
    );
    final finalBytes = Uint8List.fromList(decryptedBytes.sublist(paddingLength));
    return finalBytes;
  }

  static Future<Uint8List> rsaEncryptRaw(AsymmetricKeyPair key, Uint8List data) async {
    return await compute(
      rsaEncryptEntryPoint,
      {
        'key': key,
        'data': data
      }
    );
  }
  static Uint8List rsaEncryptEntryPoint(Map args){
    final key = args['key'];
    final data = args['data'];

    final rsa = Encrypt.Encrypter(Encrypt.RSA(
      publicKey: key.publicKey,
      privateKey: key.privateKey,
      encoding: Encrypt.RSAEncoding.OAEP));

    return Uint8List.fromList(rsa.encryptBytes(data).bytes);
  }

  static Future<Uint8List> rsaDecryptRaw(AsymmetricKeyPair key, Uint8List data) async {
    return await compute(
        rsaDecryptEntryPoint,
        {
          'key': key,
          'data': data
        }
    );
  }
  static Uint8List rsaDecryptEntryPoint(Map args){
    final key = args['key'];
    final data = args['data'];

    final rsa = Encrypt.Encrypter(Encrypt.RSA(
        publicKey: key.publicKey,
        privateKey: key.privateKey,
        encoding: Encrypt.RSAEncoding.OAEP));

    return Uint8List.fromList(rsa.decryptBytes(Encrypt.Encrypted(data)));
  }

  static Uint8List sign(AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> key, Uint8List data){
    final signer = Encrypt.Signer(
        Encrypt.RSASigner(
            Encrypt.RSASignDigest.SHA256,
            publicKey: key.publicKey,
            privateKey: key.privateKey
        )
    );

    return signer.signBytes(data).bytes;
  }
}