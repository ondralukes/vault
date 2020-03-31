import 'package:flutter/material.dart';

class VaultMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: SafeArea(
            child: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBar(
          labelColor: Theme.of(context).primaryColor,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: <Widget>[
            Tab(
              text: 'Messages',
              icon: Icon(Icons.message),
            ),
            Tab(
              text: 'Settings',
              icon: Icon(Icons.settings),
            )
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            Text('Messages'),
            Text('Settings')
          ],
        ),
        backgroundColor: Theme.of(context).backgroundColor,
      ),
    )),
    color: Theme.of(context).backgroundColor,);
  }
}
