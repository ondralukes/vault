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

  var privateHex = Buffer.from(bytes).toString('base64');

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
  var data = Buffer.from(rsaKey.private, 'base64');

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
  var rsa = new RSA(rsaKey.public);
  return rsa.encrypt(key, 'base64', 'hex');
}

module.exports.decryptKey = function(rsaKey, key){
  var rsa = new RSA(rsaKey.private);
  var buf = Buffer.from(key, 'base64');
  return rsa.decrypt(buf, 'hex');
}

module.exports.encryptData = function(hexKey, data){
  var key = aes.utils.hex.toBytes(hexKey);
  data = aes.utils.utf8.toBytes(data);

  var aesCtr = new aes.ModeOfOperation.ctr(key, new aes.Counter(7));
  var bytes = aesCtr.encrypt(data);

  var encrypted = Buffer.from(bytes).toString('base64');
  return encrypted;
}

module.exports.decryptData = function(hexKey, data){
  var key = aes.utils.hex.toBytes(hexKey);
  data = Buffer.from(data, 'base64');

  var aesCtr = new aes.ModeOfOperation.ctr(key, new aes.Counter(7));
  var bytes = aesCtr.decrypt(data);

  var decrypted = aes.utils.utf8.fromBytes(bytes);
  return decrypted;
}

module.exports.sign = function(rsaKey, data){
  var rsa = new RSA(rsaKey.private);
  return rsa.sign(data, 'base64', 'utf8');
}
