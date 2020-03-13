var vaults;

function init(){
  listVaults();
}

function createVault(){
  saveRSA('create new vault', () => {
    console.log('Generating vault key');
    var vaultKey = new Uint8Array(32);
    window.crypto.getRandomValues(vaultKey);
    vaultKey = toHexString(vaultKey);
    console.log('Vault key is ' + vaultKey);
    console.log('Encrypting vault name');
    var name = document.getElementById('vault-name').value;
    var encryptedName = cryptoTools.encryptData(vaultKey, name);
    console.log('Encrypted name is ' + encryptedName);
    console.log('Encrypting vault key for user ' + storedName + '.');
    var encryptedVaultKey = cryptoTools.encryptKey(decryptedRSA, vaultKey);
    console.log('Encryped vault key for user ' + storedName + ' is ' + encryptedVaultKey);
    var data = {
      codename: document.getElementById('vault-codename').value,
      name: encryptedName,
      keys: [
        {
          user: storedName,
          key: encryptedVaultKey
        }
      ]
    };
    authenticatedRequest('create new vault', '/vault/create', data, function(response, status){
      var result = document.getElementById('create-vault-result');
      if(status == 200){
        result.innerHTML = 'Created succesfully';
      } else {
        result.innerHTML = response;
      }
      listVaults();
    }, true);
  });
}

function listVaults(){
  authenticatedRequest('list vaults', '/user/get/private', {}, function(response, status){
    if(status == 200){
      var user = JSON.parse(response);
      console.log(user);
      var template = document.getElementById('sidebar-item-template');
      var oldVaults = template.parentNode.getElementsByClassName('sidebar-item-cloned');
      Array.from(oldVaults).forEach((item) => {
        item.remove();
      });
      vaults = user.vaults;
      user.vaults.forEach((vault) => {
        var clonedNode = template.cloneNode(true);
        clonedNode.style.display = "";
        clonedNode.classList.add('sidebar-item-cloned');
        clonedNode.id = 'sidebar-item-' + vault.codename;
        clonedNode.getElementsByClassName('sidebar-item-codename')[0].innerHTML = vault.codename;
        clonedNode.getElementsByClassName('sidebar-item-decrypt-btn')[0].onclick = function(){
          unlockVault(vault.codename);
        };
        template.parentNode.appendChild(clonedNode);
      });
    }
  }, false);
}

function unlockVault(codename) {
  console.log('Decrypting vault ' + name);
  saveRSA('unlock vault', () => {
    var data = vaults.find(x => x.codename == codename);
    authenticatedRequest('unlock vault', '/vault/get', data, function(response, status){
      if(status != 200){
        throwError("Failed to get vault data.");
        forgetRSA();
        return;
      }
      vault = JSON.parse(response);
      console.log('Decrypting vault key');
      var keyObj = vault.keys.find(x => x.user == storedName);
      if(!keyObj){
        throwError('Vault has no key for user ' + storedName);
        forgetRSA();
        return;
      }
      var encryptedVaultKey = keyObj.key;
      var decryptedVaultKey = cryptoTools.decryptKey(decryptedRSA, encryptedVaultKey);
      vault.key = decryptedVaultKey;
      console.log('Decrypted vault key is '+ decryptedVaultKey);
      console.log('Decrypting vault name');
      vault.name = cryptoTools.decryptData(decryptedVaultKey, vault.name);
      console.log('Vault name is ' + vault.name);
      vaults.forEach((v, i) => {
        if(v.codename == vault.codename){
          var accessToken = v.accessToken;
          vaults[i] = vault;
          vaults[i].accessToken = accessToken;
        }
      });
      forgetRSA();

      var sidebar = document.getElementById('sidebar-item-' + vault.codename);
      //Display name in sidebar
      sidebar.getElementsByClassName('sidebar-item-name')[0]
        .innerHTML = vault.name;

      sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
        .onclick = function(){
        lockVault(vault.codename);
      };
      sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
        .innerHTML = "Lock";
    }, true);
  });
}

function lockVault(codename){
  vaults.forEach((v, i) => {
    if(v.codename == codename){
      var lockedVault = {
        codename: v.codename,
        accessToken: v.accessToken
      };
      vaults[i] = lockedVault;
    }
  });

  var sidebar = document.getElementById('sidebar-item-' + vault.codename);
  //Hide name in sidebar
  sidebar.getElementsByClassName('sidebar-item-name')[0]
    .innerHTML = '[Locked]';

  sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
    .onclick = function(){
    unlockVault(vault.codename);
  };
  sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
    .innerHTML = "Unlock";
}

function hideError(){
  document.getElementById('error').style.display = 'none';
}

function throwError(err){
  console.error('Error: ' + err);
  document.getElementById('error').style.display = '';
  document.getElementById('error-message').innerHTML = err;
}

///XHR and auth overlay
var decryptedRSA;
var storedName;

var overlayURL = '';
var overlayData = '';
var overlayCallback;
var keepRSA = false;
function authenticatedRequest(message, url, data, callback, keep){
  overlayURL = url;
  overlayData = data;
  overlayCallback = callback;
  keepRSA = keep;
  if(!decryptedRSA){
    document.getElementById('overlay').style.display = "";
    document.getElementById('overlay-message').innerHTML = message;
    document.getElementById('overlay-result').innerHTML = "";
  } else {
    authenticate();
  }
}

function forgetRSA(){
  decryptedRSA = null;
  storedName = null;
}

function saveRSA(message, callback){
  authenticatedRequest(message, '/verifyToken', {}, function(response){
    callback();
  }, true);
}

function register(){
  var user = {
    name: document.getElementById('name').value,
    password: document.getElementById('password').value
  };
  var worker = new Worker('registerWorker.js');
  worker.onmessage = function(e){
    registerRequest(e.data);
  }
  worker.postMessage(user);
  setResult(false, "Generating RSA key pair. This might take a while.");
}

function registerRequest(user){
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function(){
    if(this.readyState == 4){
      if(this.status == 200){
        authenticate();
      } else {
        setResult(false, xhr.responseText, this.status);
      }
      console.log(xhr.responseText);
    }
  }
  xhr.open('POST', '/user/create', true);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(JSON.stringify(user));
}


function authenticate(){
  var req = {name: document.getElementById('name').value};
  if(decryptedRSA){
    req.name = storedName;
  }
  var password = document.getElementById('password').value
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function(){
    if(this.readyState == 4 && xhr.status == 200){
      var res = JSON.parse(xhr.responseText);
      console.log('Got token for user ' + res.user.name);
      if(!decryptedRSA){
        console.log('Decrypting user RSA...');
        res.user.rsa = cryptoTools.decryptRSA(res.user.rsa, password);
        if(!res.user.rsa.private.includes('-----BEGIN RSA PRIVATE KEY-----')){
          console.log('Failed to decrypt RSA. Wrong password?');
          setResult(false, 'Failed to decrypt RSA. Wrong password?');
          return;
        }
      } else {
        res.user.rsa = decryptedRSA;
      }
      console.log('Signing token...');
      var encryptedToken = cryptoTools.encryptToken(res.user.rsa, res.token)
      sendEncryptedToken(encryptedToken);
      if(keepRSA){
        decryptedRSA = res.user.rsa;
        storedName = res.user.name;
      } else {
        forgetRSA();
      }
    } else if(this.readyState == 4){
      setResult(false, this.responseText);
      if(!keepRSA) forgetRSA();
    }
  }
  xhr.open('POST', '/token', true);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(JSON.stringify(req));
}

function sendEncryptedToken(encryptedToken){
  var xhr = new XMLHttpRequest();
  overlayData.encryptedToken =  encryptedToken;
  xhr.onreadystatechange = function(){
    if(this.readyState == 4 && xhr.status == 200){
      setResult(true, xhr.responseText, xhr.status);
    } else if(this.readyState == 4){
      setResult(xhr.status != 401, xhr.responseText, xhr.status);
    }
  }
  xhr.open('POST', overlayURL, true);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(JSON.stringify(overlayData));
}

function setResult(verified, response, statusCode){
  var e = document.getElementById('overlay-result');
  if(!verified){
    e.innerHTML = response;
  } else {
    e.innerHTML = "Success!";
    setTimeout(function(){
      document.getElementById('overlay').style.display = "none";
      document.getElementById('name').value = "";
      document.getElementById('password').value = "";
      overlayCallback(response, statusCode);
    }, 500);
  }
}

//utils
function toHexString(byteArray) {
  return Array.from(byteArray, function(byte) {
    return ('0' + (byte & 0xFF).toString(16)).slice(-2);
  }).join('');
}
