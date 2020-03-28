import React from "react";
import * as ReactNative from "react-native";
import Text from './Text';

export default class HeadingText extends React.Component {
  render() {
    return (
      <Text>
        <ReactNative.Text style={styles.headingText}>
          {this.props.children}
        </ReactNative.Text>
      </Text>
    );
  }
}

const styles = ReactNative.StyleSheet.create({
  headingText: {
    fontSize: 50,
    padding: 50
  }
});
