const sha = require('sha.js');
const RSA = require('node-rsa');
const aes = require('aes-js');
var crypto = require('crypto');

module.exports.genRSAKey = function(){
  var rsaKey = new RSA({b: 2048});
  return rsaKey;
};

module.exports.encryptRSAKey = function(rsaKey, password){
  var aesKey = sha('sha256').update(password).digest('hex');
  console.log('AES key is ' + aesKey);

  var privateEncrypted = cryptoTools.encryptData(aesKey, rsaKey.exportKey('pkcs8-private'));

  var json = {
    public: rsaKey.exportKey('public'),
    private: privateEncrypted
  };
  return json;
}

module.exports.decryptRSA = function(rsaKey, password){
  var aesKey = sha('sha256').update(password).digest('hex');
  console.log('AES key is ' + aesKey);

  var privateDecrypted = cryptoTools.decryptData(aesKey, rsaKey.private);
  rsaKey.private = privateDecrypted;
  return rsaKey;
};

module.exports.signToken = function(rsaKey, token){
  var rsa = new RSA(rsaKey.private);
  return rsa.sign(token, 'hex', 'hex');
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
  var paddingLength = 16 - (data.length % 16);
  if(paddingLength === 16) paddingLength = 0;

  var key = aes.utils.hex.toBytes(hexKey);
  var iv = crypto.randomBytes(16);
  data = Buffer.from(data);

  var padding = crypto.randomBytes(paddingLength);
  var paddingLengthBuffer = Buffer.from([paddingLength]);

  data = Buffer.concat([padding, data]);

  var aesCbc = new aes.ModeOfOperation.cbc(key, iv);
  var bytes = aesCbc.encrypt(data);

  var allBytes = Buffer.concat([iv, paddingLengthBuffer, bytes]);
  var encrypted = Buffer.from(allBytes).toString('base64');
  return encrypted;
}

module.exports.decryptData = function(hexKey, data){
  var key = aes.utils.hex.toBytes(hexKey);
  data = Buffer.from(data, 'base64');
  var iv = data.slice(0,16);
  var paddingLength = data.slice(16,17)[0];
  data = data.slice(17);


  var aesCbc = new aes.ModeOfOperation.cbc(key, iv);
  var bytes = aesCbc.decrypt(data);


  bytes = bytes.slice(paddingLength);
  var decrypted = Buffer.from(bytes).toString('utf8');
  return decrypted;
}

module.exports.sign = function(rsaKey, data){
  var rsa = new RSA(rsaKey.private);
  return rsa.sign(data, 'base64', 'utf8');
}

module.exports.verify = function(rsaKey, data, signature){
  var rsa = new RSA(rsaKey.public);
  return rsa.verify(data, signature, 'utf8', 'base64');
}
