import 'package:flutter/material.dart';
import 'package:vault/SignInForm.dart';
import 'package:vault/VaultList.dart';

import 'ServerAPI.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key key, this.serverAPI}) : super(key: key);

  final ServerAPI serverAPI;
  @override
  State<StatefulWidget> createState() {
    return MainMenuState();
  }
}

class MainMenuState extends State<MainMenu> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Vaults'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              final success = await widget.serverAPI.logOut();
              if(success){
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => new SignInForm(
                        serverAPI: widget.serverAPI,
                      )
                    ));
              }
            },
            icon: Icon(
              Icons.exit_to_app
            )
          )
        ],
      ),
      body: Center(
          child: Padding(
              padding: EdgeInsets.only(right: 10, left: 10),
              child: VaultList(
                serverAPI: widget.serverAPI,
              ))),
      backgroundColor: Theme.of(context).backgroundColor,
    );
  }
}
