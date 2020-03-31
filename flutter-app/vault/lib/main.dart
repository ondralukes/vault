import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vault/ServerAPI.dart';
import 'package:vault/SignUpForm.dart';

const String url = 'https://www.ondralukes.cz/vault/';

void main() => runApp(App());

class App extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return AppState(url);
  }
}

class AppState extends State<App> {
  String url;
  ServerAPI api;
  AppState(String url) : super() {
    this.url = url;
    api = ServerAPI(url);
  }
  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp
    ]);
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
            textTheme: TextTheme(
                body1: TextStyle(
                    color: Colors.grey
                ),
                headline: TextStyle(
                    color: Colors.grey,
                    fontSize: 50
                )
            )
        ),
        home: Scaffold(body: SignUpForm(
          serverAPI: api
        ))
    );
  }
}
