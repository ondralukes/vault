import React from "react";
import {View, StyleSheet} from "react-native";
import HeadingText from '../components/HeadingText';
import AuthView from './AuthView';
import MenuView from './MenuView';
import ServerAPI from '../utils/ServerAPI';

export default class AppView extends React.Component {
  constructor (props){
    super(props);
    this.state = {
      serverApi: new ServerAPI(this)
    };
    this.render = this.render.bind(this);
  }

  render() {
    if(!this.state.serverApi.isLoggedIn()){
      return (
      <AuthView
      serverApi={this.state.serverApi}/>
      );
    } else {
      return (
        <MenuView serverApi={this.state.serverApi}/>
      );
    }
  }
}
