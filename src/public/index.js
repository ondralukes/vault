/* eslint no-unused-vars: 0 */

const MessageType = Object.freeze({Anonymous:1, NotSigned: 2, Signed: 3});

const messagesChunk = 32;

var vaults;
var openedVault;
var registerWorker = new Worker('registerWorker.js');
var startTime = Date.now();
var selectedMessageType = MessageType.NotSigned;
var scrollToBottom = true;

registerWorker.onmessage = function(e){
  switch (e.data.type) {
    case 'enc':
      registerRequest(e.data.user);
      break;
    case 'gen':
      document.getElementById('gen-keypair-msg').style.display = 'none';
      break;
  }
};

function init(){
  registerWorker.postMessage({type: 'gen'});
  document.getElementById('auth-form').onsubmit = function(){
    authenticate();
    return false;
  };
  document.getElementById('register-btn').onclick = register;
  document.getElementById('cancel-auth-btn').onclick = cancelAuth;
  document.getElementById('create-vault-btn').onclick = createVault;
  document.getElementById('create-form-back-btn').onclick = showSidebar;
  document.getElementById('vault-content-back-btn').onclick = showSidebar;
  document.getElementById('section-messages-btn').onclick = function() {switchSection(0);};
  document.getElementById('section-settings-btn').onclick = function() {switchSection(1);};
  document.getElementById('textarea-icon').onclick = switchMessageType;
  document.getElementById('add-member-btn').onclick = addUser;
  document.getElementById('hide-error-btn').onclick = hideError;
  document.getElementById('sidebar-item-create').onclick = function(){closeVault(true);};
  document.getElementById('message-text').onkeydown = textareaOnKeyDown;
  document.getElementById('messages').onscroll = onScrollMessages;
  listVaults();
  setInterval(function(){
    //Update generating counter
    var time = Date.now() - startTime;
    var minutes = Math.floor(time / 60000);
    time %= 60000;
    var seconds = Math.floor(time / 1000);
    document.getElementById('gen-keypair-time').innerHTML = (minutes<10?'0':'') + minutes + ':' + (seconds<10?'0':'') + seconds;
    updateMessages();
  },1000);
  Array.from(document.getElementsByTagName('input')).forEach((input) => {
    input.onfocusout = onLostFocus;
  });

  //Fix height on mobile devices (avoid problems with address bar)
  if(window.innerWidth <= 768){
    document.getElementsByClassName('cont')[0].style.height = window.innerHeight + 'px';
  }
}

function switchMessageType(){
  selectedMessageType++;
  if(selectedMessageType == 4){
    selectedMessageType = MessageType.Anonymous;
  }
  switch(selectedMessageType){
    case MessageType.Anonymous:
    document.getElementById('textarea-icon').src = 'img/anon.svg';
    break;
    case MessageType.NotSigned:
    document.getElementById('textarea-icon').src = 'img/warn.svg';
    break;
    case MessageType.Signed:
    document.getElementById('textarea-icon').src = 'img/signed.svg';
    break;
  }
}

//only for small screens
function hideSidebar(){
  document.getElementById('sidebar').classList.add('sidebar-hidden');
}

//only for small screens
function showSidebar(){
  document.getElementById('sidebar').classList.remove('sidebar-hidden');
}

//scroll page back to normal (for mobile)
function onLostFocus(){
  if(document.body.scrollHeight > 0){
    scrollTo(0, 0);
  }
}

function switchSection(sec){
  Array.from(document.getElementsByClassName('messages-section')).forEach((item) => {
    item.style.display = sec===0?'':'none';
  });
  Array.from(document.getElementsByClassName('settings-section')).forEach((item) => {
    item.style.display = sec===1?'':'none';
  });
  Array.from(document.getElementsByClassName('section-btn')).forEach((item, i) => {
    if(sec == i){
      item.classList.add('text-inverted');
    } else {
      item.classList.remove('text-inverted');
    }
  });

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
      showSidebar();
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
      var oldVaults = vaults || {};
      vaults = {};
      user.vaults.forEach((vault) => {

        //Do not overwrite already listed vaults (it would lock them)
        if(typeof oldVaults[vault.codename] !== 'undefined'){
          vault = oldVaults[vault.codename];
        }
        vaults[vault.codename] = vault;
        var clonedNode = template.cloneNode(true);
        clonedNode.style.display = '';
        clonedNode.classList.add('sidebar-item-cloned');
        clonedNode.id = 'sidebar-item-' + vault.codename;
        clonedNode.getElementsByClassName('sidebar-item-codename')[0].innerHTML = vault.codename;
        clonedNode.getElementsByClassName('sidebar-item-decrypt-btn')[0].onclick = function(e){
          e.stopPropagation();
          var codename = e.target.parentNode.id.substring('sidebar-item-'.length);
          unlockVault(codename);
        };
        clonedNode.addEventListener('click', function(){
          openVault(vault.codename);
        }, false);
        if(typeof vault.key !== 'undefined'){
          clonedNode.getElementsByClassName('sidebar-item-decrypt-btn')[0]
          .onclick = function(e){
            e.stopPropagation();
            var codename = e.target.parentNode.id.substring('sidebar-item-'.length);
            lockVault(codename);
          };
          clonedNode.getElementsByClassName('sidebar-item-decrypt-btn')[0]
          .innerHTML = 'Lock';
        }
        template.parentNode.insertBefore(clonedNode, template.parentNode.firstChild);
      });
    }
  }, false);
}

function unlockVault(codename, update, open) {
  if(typeof open === 'undefined') open = true;
  if(typeof update === 'undefined') update = false;
  console.log('Decrypting vault ' + name);
  var sidebar = document.getElementById('sidebar-item-' + codename);
  sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
  .innerHTML = 'Unlocking...';
  saveRSA('unlock vault', () => {
    var data = {
      codename: vaults[codename].codename,
      accessToken: vaults[codename].accessToken
    };
    authenticatedRequest('unlock vault', '/vault/get', data, function(response, status){
      if(status != 200){
        throwError('Failed to get vault data.');
        sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
        .innerHTML = 'Unlock';
        forgetRSA();
        return;
      }
      var vault = JSON.parse(response);
      console.log('Decrypting vault key');
      var keyObj = vault.keys.find(x => x.user == storedName);
      if(!keyObj){
        throwError('Vault has no key for user ' + storedName);
        sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
        .innerHTML = 'Unlock';
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
      var v = vaults[vault.codename];
      if(v){
        var accessToken = v.accessToken;
        vaults[vault.codename] = vault;
        vaults[vault.codename].accessToken = accessToken;
      }
      forgetRSA();

      var sidebar = document.getElementById('sidebar-item-' + vault.codename);
      //Display name in sidebar
      sidebar.getElementsByClassName('sidebar-item-name')[0]
      .innerHTML = vault.name;

      sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
      .onclick = function(e){
        e.stopPropagation();
        var codename = e.target.parentNode.id.substring('sidebar-item-'.length);
        lockVault(codename);
      };
      sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
      .innerHTML = 'Lock';

      if(open) openVault(codename);
      if(update) updateVaultInfo(codename);
    }, true);
  });
}

function lockVault(codename){
  var v = vaults[codename];
  var lockedVault = {
    codename: v.codename,
    accessToken: v.accessToken
  };
  vaults[codename] = lockedVault;

  var sidebar = document.getElementById('sidebar-item-' + codename);
  //Hide name in sidebar
  sidebar.getElementsByClassName('sidebar-item-name')[0]
  .innerHTML = '[Locked]';

  sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
  .onclick = function(e){
    e.stopPropagation();
    var codename = e.target.parentNode.id.substring('sidebar-item-'.length);
    unlockVault(codename);
  };
  sidebar.getElementsByClassName('sidebar-item-decrypt-btn')[0]
  .innerHTML = 'Unlock';

  if(openedVault == codename){
    closeVault();
  }
}

function openVault(codename){
  openedVault = codename;
  var v = vaults[codename];
  if(typeof v.name === 'undefined'){
    unlockVault(codename);
  } else {
    newMessageIndex = v.messagesCount;
    oldMessageIndex = v.messagesCount;
    waitingForMessages = false;
    document.getElementById('vault-content').style.display = '';
    document.getElementById('create-form').style.display = 'none';
    updateVaultInfo(codename);
    switchSection(0);
    clearMessages();
    hideSidebar();
  }
}

function updateVaultInfo(codename){
  var v = vaults[codename];
  Array.from(document.getElementsByClassName('vault-name-ins')).forEach((item) => {
    item.innerHTML = v.name;
  });
  Array.from(document.getElementsByClassName('vault-codename-ins')).forEach((item) => {
    item.innerHTML = v.codename;
  });

  var memberTemplate = document.getElementById('vault-member-template');
  //Clear member list
  Array.from(
    memberTemplate.parentNode.getElementsByClassName('vault-member-generated')
  ).forEach((elem) => {
    elem.remove();
  });

  //Add member
  v.keys.forEach((key) => {
    var cloned = memberTemplate.cloneNode(true);
    cloned.classList.add('vault-member-generated');
    cloned.style.display = '';
    cloned.getElementsByClassName('ins-member-name')[0].innerHTML = key.user;
    cloned.getElementsByClassName('ins-member-key')[0].value = key.key;
    memberTemplate.parentNode.insertBefore(cloned, memberTemplate.nextSibling);
  });
}

function closeVault(hide){
  hide = hide || false;
  document.getElementById('vault-content').style.display = 'none';
  document.getElementById('create-form').style.display = '';
  document.getElementById('create-vault-result').innerHTML = '';
  openedVault = null;
  if(hide) hideSidebar();
}

function textareaOnKeyDown(e){
  if(e.keyCode === 13){
    var messageText = document.getElementById('message-text').value;
    var type = selectedMessageType;
    if(type == MessageType.Signed){
      saveRSA('sign a message', () => {
        sendMessage(messageText, MessageType.Signed);
        forgetRSA();
      }, true);
    } else {
      sendMessage(messageText, type);
    }
    document.getElementById('message-text').value = '';
    e.preventDefault();
  }
}

function sendMessage(messageText, type) {
  messageText = messageText.replace(/\n/g, '<br>');

  var message = {
    content: messageText,
    length: messageText.length,
    timestamp: Date.now()
  };

  switch(type){
    case MessageType.Anonymous:
    break;
    case MessageType.NotSigned:
    message.sender = storedName;
    break;
    case MessageType.Signed:
    message.sender = storedName;
    message.signature = cryptoTools.sign(decryptedRSA, message.content + 'T' + message.timestamp);
    break;
  }

  var vault = getOpenVault();
  var encryptedMessage = cryptoTools.encryptData(vault.key, JSON.stringify(message));
  console.log('Encrypted data is ' + encryptedMessage);
  console.log('Sending...');
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if(this.readyState == 4){
      if(this.status == 200){
        console.log('Sent.');
      } else {
        console.log('Sending failed.');
      }
    }
  };
  xhr.open('POST', '/message/send', true);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(JSON.stringify(
    {
      codename: vault.codename,
      accessToken: vault.accessToken,
      message: encryptedMessage
    }
  ));
}

function showMessage(message, newMessage){
  //Add message to GUI
  var template = document.getElementById('message-template');
  var cloned = template.cloneNode(true);
  cloned.style.display = '';
  cloned.getElementsByClassName('message-text')[0].innerHTML = message.content;
  switch(message.type){
    case MessageType.Anonymous:
    cloned.getElementsByClassName('message-icon')[0].src = 'img/anon.svg';
    cloned.getElementsByClassName('message-sender')[0].innerHTML = '[Anonymous]';
    break;
    case MessageType.NotSigned:
    cloned.getElementsByClassName('message-icon')[0].src = 'img/warn.svg';
    cloned.getElementsByClassName('message-sender')[0].innerHTML = message.sender;
    break;
    case MessageType.Signed:
    cloned.getElementsByClassName('message-icon')[0].src = 'img/signed.svg';
    cloned.getElementsByClassName('message-sender')[0].innerHTML = message.sender;
    break;
  }
  cloned.classList.add('message-generated');
  if(newMessage){
    template.parentNode.appendChild(cloned);
  } else {
    template.parentNode.insertBefore(cloned, template);
  }
  document.getElementById('message-text').value = '';
}

function clearMessages(){
  Array.from(document.getElementsByClassName('message-generated')).forEach((item) => {
    item.remove();
  });

}

var oldMessageIndex;
var newMessageIndex;
var loadNewerOrOlder = true;
var waitingForMessages = false;

async function getMessages(newMessage){

  var vault = getOpenVault();

  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = async function() {
    if(this.readyState == 4){
      if(this.status == 200){
        console.log(JSON.parse(this.responseText));
        var messages = JSON.parse(this.responseText);

        //Decrypt messages
        await asyncForEach(messages, async (item, i) => {
          var decryptedJSON = cryptoTools.decryptData(vault.key, item);
          console.log(decryptedJSON);
          var message = JSON.parse(decryptedJSON);
          if(typeof message.sender === 'undefined'){
            message.type = MessageType.Anonymous;
          } else if(typeof message.signature === 'undefined'){
            message.type = MessageType.NotSigned
          } else {
            message.type = MessageType.Signed;
          }

          //Check message legnth
          if(message.content.length !== message.length){
            message.content = '[Corrupted]';
            message.type = MessageType.NotSigned;
          }
          //Check message signature (if provided)
          if(message.type === MessageType.Signed){
            var signatureValid = await verifySignature(message);
            if(!signatureValid){
              message.content = '[Corrupted]';
              message.sender = '[Corrupted]';
              message.type = MessageType.NotSigned;
            }
          }
          messages[i] = message;
        });
        if(!newMessage) messages.reverse();
        messages.forEach((message) => {
          showMessage(message, newMessage);
        });
        if(newMessage){
          newMessageIndex += messages.length;
        } else {
          oldMessageIndex -= messages.length;
        }
        if(scrollToBottom){
          var messagesElement = document.getElementById('messages');
          messagesElement.scrollTo(0, messagesElement.scrollHeight);
        }
      }
      waitingForMessages = false;
    }
  };
  xhr.open('POST', '/message/get', true);
  xhr.setRequestHeader('Content-Type', 'application/json');
  var req = {
    codename: vault.codename,
    accessToken: vault.accessToken,
  };
  if(newMessage){
    req.offset = newMessageIndex;
    req.count = messagesChunk;
  } else {
    req.offset = oldMessageIndex - messagesChunk;
    req.count = messagesChunk;
    if(req.offset < 0){
      req.count += req.offset;
      req.offset = 0;
    }
  }
  if(req.count > 0){
    if(waitingForMessages){
      console.log('get request blocked');
      return;
    }
    waitingForMessages = true;
    xhr.send(JSON.stringify(req));
  }
}

function verifySignature(message){
  return new Promise((resolve) => {
    getUserPublic(message.sender, (status, response) => {
      if(status !== 200){
        resolve(false);
      }
      var data = message.content + 'T' + message.timestamp;
      var signatureValid = cryptoTools.verify(response.rsa, data, message.signature);
      resolve(signatureValid);
    });
  });
}

function updateMessages(){
  if(typeof openedVault === 'undefined'){
    return;
  }
  if(openedVault == null){
    return;
  }
  var newTrigger = document.getElementById('new-messages-load-trigger');
  var parentBounding = newTrigger.parentNode.getBoundingClientRect();
  var bounding;
  if(loadNewerOrOlder){
    bounding = newTrigger.getBoundingClientRect();
    if(bounding.top <= parentBounding.bottom + 50){
      getMessages(true);
    }
  } else {
    var oldTrigger = document.getElementById('old-messages-load-trigger');
    bounding = oldTrigger.getBoundingClientRect();
    if(bounding.bottom >= parentBounding.top - 50){
      getMessages(false);
    }
  }
  loadNewerOrOlder = !loadNewerOrOlder;
}

function onScrollMessages(){
  var messagesElement = document.getElementById('messages');
  var scroll = messagesElement.offsetHeight + messagesElement.scrollTop;
  if(scroll + 50 >= messagesElement.scrollHeight){
    scrollToBottom = true;
  } else {
    scrollToBottom = false;
  }
}

function hideError(){
  document.getElementById('error').style.display = 'none';
}

function throwError(err){
  console.error('Error: ' + err);
  document.getElementById('error').style.display = '';
  document.getElementById('error-message').innerHTML = err;
}

function getOpenVault(){
  return vaults[openedVault];
}

function addUser(){
  var username = document.getElementById('new-member-name').value;
  getUserPublic(username, (statusCode, resp) => {
    if(statusCode == 200){
      console.log('Encrypting key for user ' + username);
      var encryptedKey = cryptoTools.encryptKey(resp.rsa, getOpenVault().key);
      var key =
      {
        user: username,
        key: encryptedKey
      };
      var req = {
        key: key,
        codename: getOpenVault().codename
      };
      authenticatedRequest('add key to vault', '/vault/member/add', req, (response, status) => {
        if(status != 200){
          throwError(response);
          forgetRSA();
        } else {
          //Re-unlock vault
          var vault = getOpenVault();
          unlockVault(vault.codename, true, false);
        }
      }, true);
    } else {
      throwError(resp);
    }
  });
}

function getUserPublic(name, callback){
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if(this.readyState == 4){
      if(this.status == 200){
        callback(this.status, JSON.parse(this.responseText));
      } else {
        callback(this.status, this.responseText);
      }
    }
  };
  xhr.open('POST', '/user/get/public', true);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(JSON.stringify(
    {
      name: name
    }
  ));
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
    document.getElementById('overlay').style.display = '';
    document.getElementById('overlay-message').innerHTML = message;
    document.getElementById('overlay-result').innerHTML = '';
    Array.from(document.getElementsByClassName('first-login-only')).forEach((item) => {
      if(!storedName){
        item.style.display = '';
      } else {
        item.style.display = 'none';
      }
    });
    if(storedName){
      document.getElementById('password').focus();
    } else {
      document.getElementById('name').focus();
    }
  } else {
    authenticate();
  }
}

function cancelAuth(){
  document.getElementById('overlay').style.display = 'none';
}

function forgetRSA(){
  decryptedRSA = null;
}

function saveRSA(message, callback){
  authenticatedRequest(message, '/verifyToken', {}, function(){
    callback();
  }, true);
}

function register(){
  var user = {
    name: document.getElementById('name').value,
    password: document.getElementById('password').value
  };

  registerWorker.postMessage({type: 'enc', user: user});
  setResult(false, 'Encrypting RSA key pair. This might take a while.');
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
  if(storedName) req.name = storedName;
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
      storedName = res.user.name;
      if(keepRSA){
        decryptedRSA = res.user.rsa;
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
      registerWorker.terminate();
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
    e.innerHTML = 'Success!';
    setTimeout(function(){
      document.getElementById('overlay').style.display = 'none';
      document.getElementById('name').value = '';
      document.getElementById('password').value = '';
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

async function asyncForEach(arr, callback){
  for(var i = 0;i < arr.length;i++){
    await callback(arr[i], i);
  }
}
