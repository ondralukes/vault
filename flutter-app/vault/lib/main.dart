import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vault/utils/Classes.dart';
import 'package:vault/utils/LocalStorage.dart';
import 'package:vault/utils/ServerAPI.dart';
import 'package:vault/pages/SignUpForm.dart';

const String url = 'https://www.ondralukes.cz/vault/';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState(url);
  }
}

class AppState extends State<App> {
  static const platform = const MethodChannel('com.ondralukes.vault/notification');
  String url;
  ServerAPI api;
  AppState(String url) : super() {
    this.url = url;
    api = ServerAPI(url);
    Vault.serverAPI = api;
  }
  @override
  void initState(){
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Vault',
        theme: ThemeData(
            primaryColor: Colors.grey,
            backgroundColor: Colors.grey[800],
            accentColor: Colors.grey[200],
            inputDecorationTheme: InputDecorationTheme(
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.grey)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.grey)),
              errorBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: Theme.of(context).errorColor)),
              focusedErrorBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: Theme.of(context).errorColor)),
            ),
            textTheme: TextTheme(
                body1: TextStyle(color: Colors.grey),
                body2: TextStyle(color: Colors.grey[800]),
                subhead: TextStyle(color: Colors.grey, fontSize: 20),
                headline: TextStyle(color: Colors.grey, fontSize: 50)).apply(
              fontFamily: Platform.isIOS ? "Courier" : "monospace"
            )),
        home: Scaffold(body: SignUpForm(serverAPI: api)));
  }
}
