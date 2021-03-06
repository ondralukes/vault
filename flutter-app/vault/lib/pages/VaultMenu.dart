import 'package:flutter/material.dart';
import 'package:vault/widgets/MessagesWidget.dart';
import 'package:vault/widgets/SettingsWidget.dart';
import 'package:vault/widgets/VaultList.dart';

import '../utils/Classes.dart';

class VaultMenu extends StatelessWidget {
  const VaultMenu({key, this.vault, this.vaultList}) : super(key: key);
  final VaultListState vaultList;
  final Vault vault;
  @override
  Widget build(BuildContext context) {
    Vault.serverAPI.setContext(context);
    return Container(
      child: SafeArea(
          child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
              title: Text(this.vault.name),
              backgroundColor: Theme.of(context).backgroundColor,
              bottom: TabBar(
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
              )),
          body: TabBarView(
            children: <Widget>[
              MessagesWidget(vault: vault, vaultList: vaultList),
              SettingsWidget(vault: vault),
            ],
          ),
          backgroundColor: Theme.of(context).backgroundColor,
        ),
      )),
      color: Theme.of(context).backgroundColor,
    );
  }
}
