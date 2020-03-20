const http = require('supertest-session')('http://localhost:8080');
const aes = require('aes-js');
const RSA = require('node-rsa');
const crypto = require('crypto');

const username = '͚:;ꇞp₈ћVᵖbϤٳ赘ʭ|x⹨̀Г핂(6A*槬�䒝ᛎS';
const messageText = '/谶ͺЈ=Wk뿯=钪嶏ݛҭiւ谴ͯF఑䙍坳9۾Ԇ摯螙 ﾇ~烸';

const registerParams = {
  name: username,
  rsa:
  {
    public:'-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6ImcLcPxtgCMq+bm2N0xIQ0B6/orypGg4UsUo6vPaQ5J+z9LkTSvFYej9bOnXQEoX41T1hZJzcguRd8uI2zxI8lABOQJxoO/31W6Mk5JVyHpQk2xUMwkbC9FgaeKsKR4YDN3Mwl2nmtBJGWRmoFvs23dcnvBh6osOCAHV5v7SFExbZpmG8MvEkApLjFcG1w7wzeU9Cw7efDdR7fpwPiBowUpn35lBT2mAyxUAWuUbioV3skUXghUCRCqPuYTMw0kiL1Q7gv+aPmq64AF3b6N+GQhXst5QlgbwbQ2r+ycctgx2FcXp+nmSDdFWoYytIvDqN+tzVGrdgQ2lF8AJ2TMlQIDAQAB-----END PUBLIC KEY-----',
    private:'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'
  }
};

const userRsaPrivate = '-----BEGIN RSA PRIVATE KEY-----\nMIIEogIBAAKCAQEA6ImcLcPxtgCMq+bm2N0xIQ0B6/orypGg4UsUo6vPaQ5J+z9L\nkTSvFYej9bOnXQEoX41T1hZJzcguRd8uI2zxI8lABOQJxoO/31W6Mk5JVyHpQk2x\nUMwkbC9FgaeKsKR4YDN3Mwl2nmtBJGWRmoFvs23dcnvBh6osOCAHV5v7SFExbZpm\nG8MvEkApLjFcG1w7wzeU9Cw7efDdR7fpwPiBowUpn35lBT2mAyxUAWuUbioV3skU\nXghUCRCqPuYTMw0kiL1Q7gv+aPmq64AF3b6N+GQhXst5QlgbwbQ2r+ycctgx2FcX\np+nmSDdFWoYytIvDqN+tzVGrdgQ2lF8AJ2TMlQIDAQABAoIBADaOkqXqIvughWCP\ne/nFa5Fli93hhASyxhwVkXIVDUSIpbLc1s3qnmleuYkb7VhUvTQt5E2GTSqKnNCn\n3BtTo//RZ8O9/M0mfA3Z/yVuWKaoviFgOQnL23/GV3hj5pYrAFMRwBWpUrs4TsBL\nVC370Ek4rYv+nRlHQ7inSxGy9vGwKGFTh22NFrgvzAGX2R2LqxlrzaUSwXgHSzKL\nB/FMk+jtP+fpYr0lKFUpSIVoQHz5JSDogPYg73OF83JH4jeufAjeoNRA+RdN1J8r\nFdzXnE7buuZstgSLM0ARiC7CLrTsr0fqAZAdXU6JD5bUL/F1pNEGO3EESAqfpql9\ndg6hQsECgYEA/o7U/Ro/0Zy8Vt9rGLB5LkGINioACroKEWZ+KkNvR0shSuubbXjD\ng4Q7dmFwvziakWcWpfKHQ3w0zt4b1N9tNQqpiB9dKKEUgEnkPNdJ5NVTu9It6Btl\nk/tkhOqBGf2T2D4Hr4jqCd/iSEeGHf8rnayQZjvFRJq5WasbyZY4u38CgYEA6drX\n6WMz6PWKJSGwxh/zsPwb8H1yJFDwEPoplw9xKoji7HgPiwUFGURO8I9zaLOrL9rV\nTBQY0Ea1YYBNO2dTa4HlRW30I/YhtGeKYt29f70rZ+kxNLG3QyABPRZ+/4rr1rqn\nsK1E5hDZrn3CbqduKZqglkyO6jRnnI8nhCbC0esCgYB8WiwD5KHOdQGwcn3v1q2s\nAglXZFcW5mDqtSXm4YBn1HTUE5qe9MKV6a/emaUpVK51X2W59WtMdU2azPfNmsPP\niIDe5Wtt4JqSPQaJDiaj6e54rykL3O5XRxSItcIRf0WM+mhowLqLzlnNM1t6JeAZ\nq2Xy+znX1Lm86xCs/nyCYwKBgH3EkoYUMiDBnRAnNFj5aifvDl+iN7bMSK/4ulFh\nnq0PfWtLjqBnjLxv/jxmCd1vc0uDV19ZF5c7z+SmCeM+yKBy9YkHf1uvzaSmYsiV\nFIsUg7mYsjvyr+rL1Z6y8I4ien+7VuAv73QD7+5l+CFmrlp1rJPojJvsnySV4Nyz\ns+cNAoGAKkrzAysmM0EGrz4sAgXqTCEiBbkPnF4tsef7NbZpdjNKPZ/xu7x2Vg6g\nsP/LZ0fQ1oHERDCxO/44ktlW/nh30xR1c804RSGfMCj5XNWPE2vRvLzlluYQwBdx\nLueTDa+hrMJAWaNOnEtUmHXpuHhyuU+SsKr/Lo0F2vZOuCFcpyc=\n-----END RSA PRIVATE KEY-----';

const userRsa = {
  public: registerParams.rsa.public,
  private: userRsaPrivate
};

const vaultName = '󒡴YJ]𼊣,򕨂C򂃦杪糴Ƣӝ􇆠󙒆񿕋ɲ릿S奋􆺏ϛ󏯜郲񡛼$Ãչp)9鼩';
const vaultCodename = '󸳇񳍾򥼌桗񳠲ֽڝ񅞺􉉋`@ǯ߃M^ȃ͚ά򘥄ߑ㛥拑�ͽ尶첞l♋B1𙞌';

var lockedVault;
var vaultKey;

describe('Testing webpage', () => {
  it('root page should be available', async (done) =>{
    var res = await http.get('/');
    expect(res.statusCode).toEqual(200);
    done();
  });
});
describe('Testing user registration' , () => {
  it('can register new user', async (done) =>{
    var res = await http
    .post('/user/create')
    .send(registerParams);
    expect(res.statusCode).toEqual(200);
    done();
  });
  it('can log in', async (done) =>{
    var res = await http
    .post('/token')
    .send(registerParams);

    var data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(200);
    expect(data.token).toBeDefined();
    expect(data.user).toBeDefined();
    expect(data.user.name).toEqual(registerParams.name);
    expect(data.user.rsa).toEqual(registerParams.rsa);

    var token = data.token;
    var key = new RSA(userRsaPrivate);
    var encryptedToken = key.encryptPrivate(token, 'hex', 'hex');
    res = await http
    .post('/verifyToken')
    .send({encryptedToken: encryptedToken});
    expect(res.statusCode).toEqual(200);
    done();
  });
});

describe('Testing vaults', () => {
  it('can create vault', async (done) =>{
    var res = await http
    .post('/token')
    .set('Accept', 'application/json')
    .send(registerParams);

    var data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(200);
    expect(data.token).toBeDefined();
    var token = data.token;
    var key = new RSA(userRsaPrivate);
    var encryptedToken = key.encryptPrivate(token, 'hex', 'hex');

    vaultKey = await crypto.randomBytes(32);
    var encryptedVaultKey = encryptKey(userRsa, vaultKey);

    var encryptedVaultName = encryptData(vaultKey, vaultName);

    var req = {
      encryptedToken: encryptedToken,
      codename: vaultCodename,
      keys: [
        {
          key: encryptedVaultKey,
          user: username
        }
      ],
      name: encryptedVaultName
    };
    res = await http
    .post('/vault/create')
    .send(req);
    expect(res.statusCode).toEqual(200);
    done();
  });

  it('can list vaults', async (done) =>{
    var res = await http
    .post('/token')
    .set('Accept', 'application/json')
    .send(registerParams);

    var data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(200);
    expect(data.token).toBeDefined();
    var token = data.token;
    var key = new RSA(userRsaPrivate);
    var encryptedToken = key.encryptPrivate(token, 'hex', 'hex');
    res = await http
    .post('/user/get/private')
    .send({encryptedToken: encryptedToken});
    expect(res.statusCode).toEqual(200);
    var data = JSON.parse(res.text);
    expect(data.rsa).toEqual(registerParams.rsa);
    expect(data.vaults).toHaveLength(1);
    lockedVault = data.vaults[0];
    expect(lockedVault.codename).toBeDefined();
    expect(lockedVault.accessToken).toBeDefined();
    done();
  });

  it('can unlock vault', async (done) =>{
    var res = await http
    .post('/token')
    .set('Accept', 'application/json')
    .send(registerParams);

    var data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(200);
    expect(data.token).toBeDefined();
    var token = data.token;
    var key = new RSA(userRsaPrivate);
    var encryptedToken = key.encryptPrivate(token, 'hex', 'hex');

    var req = {
      encryptedToken: encryptedToken,
      codename: lockedVault.codename,
      accessToken: lockedVault.accessToken
    };

    res = await http
    .post('/vault/get')
    .send(req);
    expect(res.statusCode).toEqual(200);
    var data = JSON.parse(res.text);
    expect(data.codename).toEqual(lockedVault.codename);
    expect(data.name).toBeDefined();
    expect(data.keys).toHaveLength(1);
    expect(data.keys[0].key).toBeDefined();
    expect(data.keys[0].user).toEqual(username);
    expect(data.messagesCount).toEqual(0);
    done();
  });
});

describe('Testing messages', () => {
  it('can send messages', async (done) => {
    var res = await http
    .post('/token')
    .set('Accept', 'application/json')
    .send(registerParams);

    var data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(200);
    expect(data.token).toBeDefined();
    var token = data.token;
    var key = new RSA(userRsaPrivate);
    var encryptedToken = key.encryptPrivate(token, 'hex', 'hex');

    var message = {
      content: messageText,
      length: messageText.length,
      timestamp: Date.now(),
      sender: username
    };
    message.signature = sign(userRsa, message.content + 'T' + message.timestamp);

    var encryptedMessage = encryptData(vaultKey, JSON.stringify(message));
    var req = {
      codename: lockedVault.codename,
      accessToken: lockedVault.accessToken,
      message: encryptedMessage
    };
    res = await http
    .post('/message/send')
    .send(req);
    expect(res.statusCode).toEqual(200);
    done();
  });
  it('can read messages', async (done) => {
    var res = await http
    .post('/token')
    .set('Accept', 'application/json')
    .send(registerParams);

    var data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(200);
    expect(data.token).toBeDefined();
    var token = data.token;
    var key = new RSA(userRsaPrivate);
    var encryptedToken = key.encryptPrivate(token, 'hex', 'hex');

    var req = {
      codename: lockedVault.codename,
      accessToken: lockedVault.accessToken,
      offset: 0,
      count: 32
    };

    res = await http
    .post('/message/get')
    .send(req);
    expect(res.statusCode).toEqual(200);
    var data = JSON.parse(res.text);
    expect(data).toHaveLength(1);
    var encryptedMessage = data[0];
    var message = JSON.parse(decryptData(vaultKey, encryptedMessage));
    expect(message.sender).toEqual(username);
    expect(message.length).toEqual(messageText.length);
    expect(message.content).toEqual(messageText);
    var signature = message.signature;
    var signedText = message.content + 'T' + message.timestamp;
    var isValid = verify(userRsa, signedText, signature);
    expect(isValid).toEqual(true);
    done();
  });
});

function encryptData(hexKey, data){
  var key = Buffer.from(hexKey, 'hex');
  data = aes.utils.utf8.toBytes(data);

  var aesCtr = new aes.ModeOfOperation.ctr(key, new aes.Counter(7));
  var bytes = aesCtr.encrypt(data);

  var encrypted = Buffer.from(bytes).toString('base64');
  return encrypted;
}

function decryptData(hexKey, data){
  var key = Buffer.from(hexKey, 'hex');
  data = Buffer.from(data, 'base64');

  var aesCtr = new aes.ModeOfOperation.ctr(key, new aes.Counter(7));
  var bytes = aesCtr.decrypt(data);

  var decrypted = aes.utils.utf8.fromBytes(bytes);
  return decrypted;
}

function encryptKey(rsaKey, key){
  var rsa = new RSA(rsaKey.public);
  return rsa.encrypt(key, 'base64', 'hex');
}

function sign(rsaKey, data){
  var rsa = new RSA(rsaKey.private);
  return rsa.sign(data, 'base64', 'utf8');
}

function verify(rsaKey, data, signature){
  var rsa = new RSA(rsaKey.public);
  return rsa.verify(data, signature, 'utf8', 'base64');
}
