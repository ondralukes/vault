import React from 'react';
import * as ReactNative from "react-native";

export default class ServerAPI {
  constructor(appView) {
    this.auth = {};
    this.appView = appView;
    this.logOut = this.logOut.bind(this);
  }

  prepareRSA(callback){
    ReactNative.NativeModules.Crypto.generateRSA((res) => {
      if(res.err){
        ReactNative.Alert.alert('Oh no!', 'RSA generating failed:\n' + res.err);
        return;
      }
      this.auth.rsa = res;
      callback();
    });
  }

  isRSAReady(){
    return typeof this.auth.rsa !== 'undefined' && this.auth.rsa !== null;
  }

  isLoggedIn(){
    return typeof this.auth.name !== 'undefined' && this.auth.name !== null && this.isRSAReady();
  }

  register(name, password){
    ReactNative.NativeModules.Crypto.encryptRSA(this.auth.rsa, password,
      async (res) => {
        if(res.err){
          ReactNative.Alert.alert('Oh no!', 'RSA encrypting failed:\n' + res.err);
          return;
        }

        //Send request
        var response = await fetch('https://www.ondralukes.cz/vault/user/create', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            name: name,
            rsa: res
          })
        });
        if(response.status !== 200){
          ReactNative.Alert.alert(
            'Oh no!',
            'Server rejected your request:\n' + (await response.text())
          );
          return;
        }
        this.auth.name = name;
        //Update UI
        this.appView.forceUpdate();
      });
    }

    logOut(){
      this.auth.name = null;
      this.auth.rsa = null;
      //Update UI
      this.appView.forceUpdate();
    }
  async login(name, password){
    var tokenResult = await fetch('https://www.ondralukes.cz/vault/token',{
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        name: name
      })
    });
    if(tokenResult.status !== 200){
      ReactNative.Alert.alert(
        'Oh no!',
        'Failed to get token:\n' + (await tokenResult.text())
      );
      return;
    }
    var json = await tokenResult.json();
    var token = json.token;
    var user = json.user;
    ReactNative.NativeModules.Crypto.decryptRSA(user.rsa, password,
      async (res) => {
        if(res.err){
          ReactNative.Alert.alert('Oh no!', 'RSA decrypting failed:\n' + res.err);
          return;
        }
        user.rsa = res;
        ReactNative.NativeModules.Crypto.signToken(user.rsa, token,
        async (res) => {
          if(res.err){
            ReactNative.Alert.alert('Oh no!', 'Token signing failed:\n' + res.err);
            return;
          }
          var verifyResult = await fetch('https://www.ondralukes.cz/vault/verifyToken',{
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              signedToken: res.signedToken
            })
          });
          if(verifyResult.status !== 200){
            ReactNative.Alert.alert(
              'Oh no!',
              'Failed to verify token:\n' + (await verifyResult.text())
            );
            return;
          }
          this.auth = {
            name: user.name,
            rsa: user.rsa
          };
          this.appView.forceUpdate();
        });

      });
  }
}
