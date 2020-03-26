import React from "react";
import * as ReactNative from "react-native";
import Text from './Text';
import LinkText from './LinkText';
import TextInput from './TextInput';
import Button from './Button';

export default class RegisterForm extends React.Component {
  constructor (props){
    super(props);
    this.state = {
      rsa: null
    };
    this.nameInput = React.createRef();
    this.passwordInput = React.createRef();
    this.passwordConfirmInput = React.createRef();
    this.onSubmit = this.onSubmit.bind(this);
    this.render = this.render.bind(this);

    //Generate RSA keypair for later use
    ReactNative.NativeModules.Crypto.generateRSA((res) => {
      if(res.err){
        ReactNative.Alert.alert('Oh no!', 'RSA generating failed:\n' + res.err);
        return;
      }
      this.setState({
        rsa: res
      });
    });
  }
  async onSubmit() {
    var name = this.nameInput.current.state.value;
    var password = this.passwordInput.current.state.value;
    var passwordConfirm = this.passwordConfirmInput.current.state.value;
    if(password !== passwordConfirm){
      ReactNative.Alert.alert('Oh no!', 'Passwords do not match.');
      return;
    }
    ReactNative.NativeModules.Crypto.encryptRSA(this.state.rsa, password,
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
        this.props.onCompleted({
          name: name,
          rsa: this.state.rsa
        });
      });
  }
  render() {
    return (
      <ReactNative.View>
      <Text>Enter name and password:</Text>
      <TextInput
      ref={this.nameInput}
      placeholder='Name'
      />
      <TextInput
      ref={this.passwordInput}
      type='password'
      placeholder='Password'
      />
      <TextInput
      ref={this.passwordConfirmInput}
      type='password'
      placeholder='Confirm password'
      />
      {
        this.state.rsa === null ?
          <Text>Wait! We are generating your keypair.</Text>
          :
          <Button onPress={this.onSubmit}>Sign up</Button>
      }
      <LinkText onPress={this.props.onSwitchToLogin}>or click here to log in</LinkText>
      </ReactNative.View>
    );
  }
}
