import React from "react";
import {View, StyleSheet} from "react-native";
import HeadingText from '../components/HeadingText';
import AuthView from './AuthView';
import MenuView from './MenuView';
export default class AppView extends React.Component {
  constructor (props){
    super(props);
    this.state = {
      auth: null
    };
    this.onCompleted = this.onCompleted.bind(this);
    this.onLogOut = this.onLogOut.bind(this);
    this.render = this.render.bind(this);
  }

  onCompleted(res) {
    this.setState({
      auth: res
    });
  }

  onLogOut() {
    this.setState({
      auth: null
    });
  }

  render() {
    if(this.state.auth === null){
      return (
      <AuthView onCompleted={this.onCompleted}/>
      );
    } else {
      return (
        <MenuView onLogOut={this.onLogOut}/>
      );
    }
  }
}
