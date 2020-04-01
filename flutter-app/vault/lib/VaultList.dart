import 'package:flutter/material.dart';
import 'package:vault/ServerAPI.dart';
import 'package:vault/VaultRow.dart';

import 'Classes.dart';

class VaultList extends StatefulWidget {
  const VaultList({Key key, this.serverAPI}) : super(key: key);

  final ServerAPI serverAPI;
  @override
  State<StatefulWidget> createState() {
    return VaultListState();
  }
}

class VaultListState extends State<VaultList> {
  List<Vault> vaults = List<Vault>();
  @override
  void initState() {
    loadVaults();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (vaults.length == 0) {
      return CircularProgressIndicator();
    }
    return RefreshIndicator(
        backgroundColor: Theme.of(context).primaryColor,
        color: Theme.of(context).backgroundColor,
        onRefresh: loadVaults,
        child: ListView.builder(
            itemCount: vaults.length * 2,
            itemBuilder: (context, i) => buildRow(i)));
  }

  Future<void> loadVaults() async {
    final user = await widget.serverAPI.getUserData();
    final rawVaults = user['vaults'];
    setState(() {
      vaults.clear();
      rawVaults.forEach((v) => vaults.add(Vault(v)));
    });
  }

  buildRow(i) {
    if (i % 2 == 0) {
      final vault = vaults[i ~/ 2];
      return VaultRow(serverAPI: widget.serverAPI, vault: vault);
    } else
    //Ignore last divider
    if (vaults.length * 2 - 1 != i) {
      return Divider(
        color: Theme.of(context).primaryColor,
        thickness: 3,
      );
    }
  }
}
