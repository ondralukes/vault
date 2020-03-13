const sha = require('sha.js');
const RSA = require('node-rsa');
const aes = require('aes-js');

module.exports.genRSAKey = function(password){
  var aesKey = sha('sha256').update(password).digest('hex');
  console.log('AES key is ' + aesKey);
  var rsaKey = new RSA({b: 2048});

  var key = aes.utils.hex.toBytes(aesKey);
  var data = aes.utils.utf8.toBytes(rsaKey.exportKey('private'));

  var aesCtr = new aes.ModeOfOperation.ctr(key, new aes.Counter(7));
  var bytes = aesCtr.encrypt(data);

  var privateHex = aes.utils.hex.fromBytes(bytes);

  var json = {
    public: rsaKey.exportKey('public'),
    private: privateHex
  };
  return json;
};

module.exports.decryptRSA = function(rsaKey, password){
  var aesKey = sha('sha256').update(password).digest('hex');
  console.log('AES key is ' + aesKey);

  var key = aes.utils.hex.toBytes(aesKey);
  var data = aes.utils.hex.toBytes(rsaKey.private);

  var aesCtr = new aes.ModeOfOperation.ctr(key, new aes.Counter(7));
  var bytes = aesCtr.decrypt(data);

  var privateDecrypted = aes.utils.utf8.fromBytes(bytes);
  rsaKey.private = privateDecrypted;
  return rsaKey;
};

module.exports.encryptToken = function(rsaKey, token){
  var rsa = new RSA(rsaKey.private);
  return rsa.encryptPrivate(token, 'hex', 'hex');
}

module.exports.encryptKey = function(rsaKey, key){
  var rsa = new RSA(rsaKey.private);
  return rsa.encrypt(key, 'hex', 'hex');
}

module.exports.encryptData = function(hexKey, data){
  var key = aes.utils.hex.toBytes(hexKey);
  var data = aes.utils.utf8.toBytes(data);

  var aesCtr = new aes.ModeOfOperation.ctr(key, new aes.Counter(7));
  var bytes = aesCtr.encrypt(data);

  var encrypted = aes.utils.hex.fromBytes(bytes);
  return encrypted;
}
