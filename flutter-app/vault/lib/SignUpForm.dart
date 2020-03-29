import 'package:flutter/material.dart';
import 'package:vault/ChangingText.dart';
import 'package:vault/ServerAPI.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key key, this.serverAPI}) : super(key: key);

  final ServerAPI serverAPI;
  @override
  State<StatefulWidget> createState() {
    return SignUpFormState();
  }
}

class SignUpFormState extends State<SignUpForm> {
  final key = GlobalKey<FormState>();
  final resultTextKey = GlobalKey<ChangingTextState>();

  String name;
  String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Form(
            key: key,
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(25),
                  child: Center(
                    child: Text(
                      'Vault',
                      style: Theme.of(context).textTheme.headline,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return "Please enter a name.";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      this.name = value;
                    },
                    style: Theme.of(context).textTheme.body1,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      prefixIcon: Icon(
                        Icons.perm_identity,
                        color: Theme.of(context).primaryColor,
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor)),
                      errorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor)),
                      focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return "Please enter a password.";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      this.password = value;
                    },
                    style: Theme.of(context).textTheme.body1,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.vpn_key,
                          color: Theme.of(context).primaryColor),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor)),
                      errorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor)),
                      focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).errorColor)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: RaisedButton(
                    color: Colors.grey[700],
                    child: Text(
                      'Sign in',
                      style: Theme.of(context).textTheme.body1,
                    ),
                    onPressed: () async {
                      if (key.currentState.validate()) {
                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text('Processing Data')));
                        String result = await widget.serverAPI.signUp(this.name, this.password);
                        resultTextKey.currentState.changeText(result);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: ChangingText(
                    key: this.resultTextKey,
                    text: '<wait>',
                  )
                )
              ],
            )),
        backgroundColor: Colors.grey[800]);
  }
}
