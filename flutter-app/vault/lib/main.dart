import 'package:flutter/material.dart';
import 'package:vault/SignUpForm.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault',
      theme: ThemeData(
        primaryColor: Colors.grey,
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
      home: SignUpForm()
    );
  }
}
