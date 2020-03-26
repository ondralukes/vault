import React from "react";
import {View, StyleSheet} from "react-native";
import HeadingText from '../components/HeadingText';
import Button from '../components/Button';

export default class MenuView extends React.Component {
  render() {
    return (
      <View style={styles.container} className='container'>
        <HeadingText>You're in.</HeadingText>
        <Button onPress={this.props.onLogOut}>Log Out</Button>
      </View>
    );
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
