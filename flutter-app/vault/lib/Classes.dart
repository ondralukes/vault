import 'package:pointycastle/export.dart';

enum VaultState{
  Locked,
  Unlocking,
  Unlocked
}
class User {
  String name;
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> rsa;
}

class Vault {
  Vault(Map map){
    this.codename = map['codename'];
    this.accessToken = map['accessToken'];
  }

  VaultState state = VaultState.Locked;
  String codename;
  String accessToken;
}