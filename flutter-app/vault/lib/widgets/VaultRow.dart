import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vault/utils/Classes.dart';
import 'package:vault/utils/ServerAPI.dart';

import '../pages/VaultMenu.dart';

class VaultRow extends StatefulWidget{
  VaultRow({Key key, this.vault, this.serverAPI}) : super(key: key);
  final Vault vault;
  final ServerAPI serverAPI;

  @override
  State<StatefulWidget> createState() {
    return VaultRowState();
  }
}
class VaultRowState extends State<VaultRow>{
  static const animationCharacters = ['|','/','―','\\'];
  Timer timer;
  int animationState = 0;

  @override
  initState(){
    timer = Timer.periodic(
        Duration(milliseconds: 250),
            (t){
          setState(() {
          animationState++;
          animationState %= 4;
          });
        });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          switch(widget.vault.state){
            case VaultState.Locked:
              setState(() {
                widget.serverAPI.unlockVault(widget.vault).then((_){
                  setState(() {
                  });
                });
              });
              break;
            case VaultState.Unlocking:
              break;
            case VaultState.Unlocked:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VaultMenu(
                        vault: widget.vault,
                      )));
              break;
          }

        },
        child: Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(25),
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.lock,
                    size: 50,
                  )),
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle),
            ),
            Column(
              children: <Widget>[
                Text(
                  getNameText(),
                  style: Theme.of(context).textTheme.subhead,
                ),
                Text(widget.vault.codename)
              ],
            )
          ],
        ));
  }
  String getNameText(){
    switch(widget.vault.state){
      case VaultState.Locked:
        return '[Locked]';
        break;
      case VaultState.Unlocking:
        return '[' + animationCharacters[animationState] + ' Unlocking...]';
        break;
      case VaultState.Unlocked:
        return widget.vault.name;
        break;
    }
  }
}