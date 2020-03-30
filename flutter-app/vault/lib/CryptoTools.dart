import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

class CryptoTools{
  static Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> generateRSA() async {
    return await compute(CryptoTools.generateRSAEntrypoint, null);
  }
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAEntrypoint(int _){
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
}