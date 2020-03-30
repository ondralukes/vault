import 'package:flutter/material.dart';

class ChangingText extends StatefulWidget {
  const ChangingText({Key key, this.text}) : super(key: key);

  final String text;
  @override
  State<StatefulWidget> createState() {
    return ChangingTextState(text);
  }
}

class ChangingTextState extends State<ChangingText> {
  ChangingTextState(this.text);
  String text;

  setText(String text){
    setState(() {
      this.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(this.text);
  }
}
