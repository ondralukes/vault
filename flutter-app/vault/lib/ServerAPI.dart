import 'package:vault/CryptoTools.dart';
import 'package:vault/rsa_pem.dart';

class ServerAPI{
  String url;
  ServerAPI(String url){
    this.url = url;
  }

  signUp(String name, String password) async {
    var keyPair = await CryptoTools.generateRSA();
    String result = 'name: ' + name + '\npassword: ' + password + '\n';

    result += RsaKeyHelper().encodePublicKeyToPem(keyPair.publicKey);
    result += RsaKeyHelper().encodePrivateKeyToPem(keyPair.privateKey);
    return result;
  }
}