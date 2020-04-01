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
    return await compute(
      CryptoTools.encryptDataEntryPoint,
        {
          'keyBytes': keyBytes,
          'data': data
        }
    );
  }
  static String encryptDataEntryPoint(Map args){
    final keyBytes = args['keyBytes'];
    final data = args['data'];

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

  static Future<String> decryptData(Uint8List keyBytes, String data) async {
    return await compute(
        CryptoTools.decryptDataEntryPoint,
        {
          'keyBytes': keyBytes,
          'data': data
        }
    );
  }
  static String decryptDataEntryPoint(Map args){
    final keyBytes = args['keyBytes'];
    final data = args['data'];

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