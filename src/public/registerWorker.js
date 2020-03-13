importScripts('index-crypto-browserified.js');

onmessage = function(e){
  var user = e.data;
  user.rsa = cryptoTools.genRSAKey(user.password);

  //We don't the password anymore
  delete user.password;

  postMessage(user);
}
