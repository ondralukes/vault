import React from "react";
import * as ReactNative from "react-native";

export default class Text extends React.Component {
  render() {
    return (
      <ReactNative.Text style={styles.text}>{this.props.children}</ReactNative.Text>
    );
  }
}

const styles = ReactNative.StyleSheet.create({
  text: {
    textAlign: 'center',
    color: 'lightgrey'
  }
});
