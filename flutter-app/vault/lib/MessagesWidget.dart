import 'package:flutter/material.dart';

import 'MessageWidget.dart';

class MessagesWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MessagesWidgetState();
  }
}

class MessagesWidgetState extends State<MessagesWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(10), child: MessageWidget());
  }
}
