import 'package:flutter/material.dart';

import 'Classes.dart';

class VaultList extends StatefulWidget {
  const VaultList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return VaultListState();
  }
}

class VaultListState extends State<VaultList> {
  List<Vault> vaults = List<Vault>();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: vaults.length * 2, itemBuilder: (context, i) => buildRow(i));
  }

  loadVaults(List rawVaults) {
    setState(() {
      vaults.clear();
      rawVaults.forEach((v) => vaults.add(Vault(v)));
    });
  }

  buildRow(i) {
    if (i % 2 == 0) {
      final vault = vaults[i~/2];
      return Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(25),
            child: Padding(
              padding: EdgeInsets.all(10),
                child:Icon(
              Icons.lock,
              size: 50,
            )),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle
            ),
          ),
          Text(vault.codename)
        ],
      );
    } else
    //Ignore last divider
    if (vaults.length * 2 - 1 != i) {
      return
        Divider(
        color: Theme.of(context).primaryColor,
        thickness: 3,
      );
    }
  }
}
