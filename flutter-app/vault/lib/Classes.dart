import 'package:pointycastle/export.dart';

class User {
  String name;
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> rsa;
}

class Vault {
  Vault(Map map){
    this.codename = map['codename'];
    this.accessToken = map['accessToken'];
  }

  String codename;
  String accessToken;
}