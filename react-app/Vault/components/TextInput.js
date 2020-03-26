import React from "react";
import * as ReactNative from "react-native";

export default class TextInput extends React.Component {
  constructor (props){
    super(props);
    this.state = {
      value: ''
    };
  }
  render() {
    return (
      <ReactNative.TextInput
      style={styles.textInput}
      value={this.state.value}
      secureTextEntry={this.props.type == 'password'}
      placeholder={this.props.placeholder}
      onChangeText={value => {this.setState({value})}}
      />
    );
  }
}

const styles = ReactNative.StyleSheet.create({
  textInput: {
    color: 'lightgrey',
    backgroundColor: '#535353',
    borderRadius: 10,
    alignSelf: 'stretch',
    margin: 10,
    padding: 5
  }
});
