importScripts('index-crypto-browserified.js');

var rsaKey;
var rsaReady = false;
onmessage = function(e){
  switch (e.data.type) {
    case 'gen':
      rsaKey = cryptoTools.genRSAKey();
      rsaReady = true;
      postMessage(
        {
          type: 'gen',
        }
      );
      break;
    case 'enc':
      var user = e.data.user;
      while(!rsaReady);
      user.rsa = cryptoTools.encryptRSAKey(rsaKey, user.password);

      //We don't need the password anymore
      delete user.password;

      postMessage(
        {
          type: 'enc',
          user: user
        }
      );
      break;
  }
}
