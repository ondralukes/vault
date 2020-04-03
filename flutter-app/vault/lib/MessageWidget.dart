import 'package:flutter/material.dart';
import 'package:vault/Classes.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({key, this.message}): super(key: key);
  final Message message;
  @override
  Widget build(BuildContext context) {
    return Wrap(children: <Widget>[
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Theme.of(context).primaryColor),
        child: Padding(
          padding: EdgeInsets.all(5),
            child: Text(message.content, style: Theme.of(context).textTheme.body2)),
      )
    ]);
  }
}
