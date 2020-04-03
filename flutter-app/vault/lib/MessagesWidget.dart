import 'dart:async';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(10),
        child: ListView.builder(
            controller: scrollController,
            reverse: true,
            itemCount: widget.vault.getMessageCount() + 1,
            itemBuilder: (context, i) => buildRow(i)));
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
      final newMessages = await widget.vault.getOlderMessages();
      setState(() {
        fetchingOlder = false;
      });
    }
    messageFetcher = Timer(Duration(milliseconds: 250), getMessages);
  }
}
