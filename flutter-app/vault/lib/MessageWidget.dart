import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vault/Classes.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({key, this.message}) : super(key: key);
  final Message message;
  @override
  Widget build(BuildContext context) {
    return Wrap(children: <Widget>[
      Container(
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).primaryColor),
          child: Padding(
              padding: EdgeInsets.all(5),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      message.type == MessageType.Corrupted
                          ? '[Corrupted]'
                          : (message.type == MessageType.Anonymous
                              ? '[Anonymous]'
                              : message.sender),
                      style: Theme.of(context)
                          .textTheme
                          .body2
                          .apply(fontSizeDelta: 5, fontWeightDelta: 3),
                    ),
                    Text(
                      message.type==MessageType.Corrupted?'[Corrupted]':message.content,
                      style: Theme.of(context).textTheme.body2,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          message.type==MessageType.Corrupted?'[Corrupted]':
                            new DateFormat.yMd().format(message.time.toLocal()) +
                                '\n' +
                                new DateFormat.jms().format(message.time.toLocal()),
                            style: Theme.of(context)
                                .textTheme
                                .body2
                                .apply(fontSizeDelta: -5)),
                        SvgPicture.asset(
                          message.type == MessageType.Signed
                              ? 'assets/signed.svg'
                              : message.type == MessageType.NotSigned
                                  ? 'assets/warn.svg'
                                  : 'assets/anon.svg',
                          width: 15,
                        )
                      ],
                    )
                  ],
                ),
              )))
    ]);
  }
}
