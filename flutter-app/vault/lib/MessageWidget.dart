import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(children: <Widget>[
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Theme.of(context).primaryColor),
        child: Padding(
          padding: EdgeInsets.all(5),
            child: Text('test', style: Theme.of(context).textTheme.body2)),
      )
    ]);
  }
}
