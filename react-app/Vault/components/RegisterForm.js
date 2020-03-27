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
    this.props.serverApi.prepareRSA(() => {
      this.forceUpdate();
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
    this.props.serverApi.register(name, password);
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
        this.props.serverApi.isRSAReady() ?
          <Button onPress={this.onSubmit}>Sign up</Button>
          :
          <Text>Wait! We are generating your keypair.</Text>
      }
      <LinkText onPress={this.props.onSwitchToLogin}>or click here to log in</LinkText>
      </ReactNative.View>
    );
  }
}
