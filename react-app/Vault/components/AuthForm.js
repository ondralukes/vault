import React from "react";
import * as ReactNative from "react-native";
import Text from './Text';
import LinkText from './LinkText';
import TextInput from './TextInput';
import Button from './Button';

export default class AuthForm extends React.Component {
  constructor (props){
    super(props);
    this.nameInput = React.createRef();
    this.passwordInput = React.createRef();
    this.onSubmit = this.onSubmit.bind(this);
  }
  async onSubmit() {
    // TODO: Check login
    this.props.onCompleted(null);
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
      <Button onPress={this.onSubmit}>Login</Button>
      <LinkText onPress={this.props.onSwitchToRegister}>or click here to sign up</LinkText>
      </ReactNative.View>
    );
  }
}
