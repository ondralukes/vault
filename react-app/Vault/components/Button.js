import React from "react";
import * as ReactNative from "react-native";
import Text from './Text'

export default class Button extends React.Component {
  render() {
    return (
      <ReactNative.TouchableOpacity
      style={styles.button}
      onPress={this.props.onPress}>
      <Text>{this.props.children}</Text>
      </ReactNative.TouchableOpacity>
    );
  }
}

const styles = ReactNative.StyleSheet.create({
  button: {
    backgroundColor: '#535353',
    margin: 10,
    padding: 5,
    borderRadius: 10
  }
});
