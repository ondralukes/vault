import React from "react";
import * as ReactNative from "react-native";
import Text from './Text';

export default class LinkText extends React.Component {
  render() {
    return (
      <Text>
        <ReactNative.Text onPress={this.props.onPress} style={styles.headingText}>
          {this.props.children}
        </ReactNative.Text>
      </Text>
    );
  }
}

const styles = ReactNative.StyleSheet.create({
  headingText: {
    color: 'lightblue'
  }
});
