import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'Classes.dart';
import 'MessageWidget.dart';

class MessagesWidget extends StatefulWidget {
  const MessagesWidget({key, this.vault}) : super(key: key);
  final Vault vault;
  @override
  State<StatefulWidget> createState() {
    return MessagesWidgetState();
  }
}

class MessagesWidgetState extends State<MessagesWidget> {
  Timer messageFetcher;
  ScrollController scrollController;

  double scroll;

  bool fetchingOlder = false;
  MessageType messageType = MessageType.Anonymous;
  String messageContent = '';

  bool sending = false;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      //Messages
      Expanded(
          child: Padding(
              padding: EdgeInsets.all(10),
              child: ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  itemCount: widget.vault.getMessageCount() + 1,
                  itemBuilder: (context, i) => buildRow(i)))),
      //Message send bar
      ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
                child: Padding(
              padding: EdgeInsets.only(right: 5, left: 5, bottom: 5),
              child: TextFormField(
                maxLines: null,
                onChanged: (value) {
                  this.messageContent = value;
                },
                keyboardType: TextInputType.multiline,
                controller: textController,
                decoration: InputDecoration(
                  hintText: messageType == MessageType.Anonymous
                      ? 'Send anonymous message'
                      : messageType == MessageType.NotSigned
                          ? 'Send message'
                          : 'Send signed message',
                ),
              ),
            )),
            Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Theme.of(context).primaryColor,
                ),
                height: 50,
                width: 50,
                margin: EdgeInsets.only(right: 5, left: 5, bottom: 5),
                child: Padding(
                    padding: EdgeInsets.all(5),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          switch (messageType) {
                            case MessageType.Anonymous:
                              messageType = MessageType.NotSigned;
                              break;
                            case MessageType.NotSigned:
                              messageType = MessageType.Signed;
                              break;
                            case MessageType.Signed:
                              messageType = MessageType.Anonymous;
                              break;
                            case MessageType.Corrupted:
                              break;
                          }
                        });
                      },
                      child: SvgPicture.asset(
                        messageType == MessageType.Anonymous
                            ? 'assets/anon.svg'
                            : messageType == MessageType.NotSigned
                                ? 'assets/warn.svg'
                                : 'assets/signed.svg',
                      ),
                    ))),
            Visibility(
                visible: !sending,
                replacement: Container(
                    margin: EdgeInsets.only(right: 5, left: 5, bottom: 5),
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator()),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Theme.of(context).primaryColor),
                  height: 50,
                  width: 50,
                  margin: EdgeInsets.only(right: 5, left: 5, bottom: 5),
                  child: IconButton(
                    iconSize: 25,
                    onPressed: () async {
                      if(messageContent.length == 0) return;
                      setState(() {
                        sending = true;
                      });
                      await widget.vault
                          .sendMessage(messageContent, messageType);
                      setState(() {
                        sending = false;
                      });
                      textController.clear();
                    },
                    icon: Icon(Icons.send),
                  ),
                )),
          ],
        ),
      )
    ]);
  }

  buildRow(i) {
    //Progress indicator at the end
    if (i == widget.vault.getMessageCount()) {
      return Visibility(
        child: Center(child: CircularProgressIndicator()),
        visible: fetchingOlder,
      );
    }
    final reversedI = widget.vault.getMessageCount() - i - 1;
    final message =
        widget.vault.getMessage(reversedI + widget.vault.oldestIndex);
    return MessageWidget(
      message: message,
    );
  }

  @override
  void initState() {
    scrollController = new ScrollController();
    messageFetcher = Timer(Duration(milliseconds: 250), getMessages);
    super.initState();
  }

  @override
  dispose() {
    messageFetcher.cancel();
    super.dispose();
  }

  getMessages() async {
    final scroll = scrollController.position.pixels;
    final maxScroll = scrollController.position.maxScrollExtent;
    if (scroll > maxScroll - 100) {
      setState(() {
        fetchingOlder = true;
      });
      await widget.vault.getOlderMessages();
      setState(() {
        fetchingOlder = false;
      });
    }
    final newMessages = await widget.vault.getNewerMessages();
    if (newMessages) {
      setState(() {});
    }
    messageFetcher = Timer(Duration(milliseconds: 250), getMessages);
  }
}
