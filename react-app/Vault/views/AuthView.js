import React from "react";
import {View, StyleSheet} from "react-native";
import HeadingText from '../components/HeadingText';
import AuthForm from '../components/AuthForm';
import RegisterForm from '../components/RegisterForm';

export default class AuthView extends React.Component {
  constructor (props){
    super(props);
    this.state = {
      type: 'login'
    };
    this.onSwitchToRegister = this.onSwitchToRegister.bind(this);
    this.onSwitchToLogin = this.onSwitchToLogin.bind(this);
  }
  onSwitchToRegister(){
    this.setState({
      type: 'register'
    });
  }
  onSwitchToLogin(){
    this.setState({
      type: 'login'
    });
  }
  render() {
    if(this.state.type == 'login'){
      return (
        <View style={styles.container} className='container'>
          <HeadingText>Login</HeadingText>
          <AuthForm
          serverApi={this.props.serverApi}
          onSwitchToRegister={this.onSwitchToRegister}
          />
        </View>
      );
    } else {
      return (
        <View style={styles.container} className='container'>
          <HeadingText>Sign up</HeadingText>
          <RegisterForm
          serverApi={this.props.serverApi}
          onSwitchToLogin={this.onSwitchToLogin}
          />
        </View>
      );
    }

  }
}

const styles = StyleSheet.create({
  container: {
    paddingTop: 50,
    flex: 1,
    backgroundColor: '#353535',
    alignItems: 'stretch',
    justifyContent: 'flex-start',
  }
});
