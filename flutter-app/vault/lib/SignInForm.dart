import 'package:flutter/material.dart';
import 'package:vault/ChangingText.dart';
import 'package:vault/MainMenu.dart';
import 'package:vault/ServerAPI.dart';
import 'package:vault/SignUpForm.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({Key key, this.serverAPI}) : super(key: key);

  final ServerAPI serverAPI;
  @override
  State<StatefulWidget> createState() {
    return SignInFormState();
  }
}

class SignInFormState extends State<SignInForm> {
  final key = GlobalKey<FormState>();
  final resultTextKey = GlobalKey<ChangingTextState>();

  String name;
  String password;
  bool canSubmit = true;
  bool showProcessIndicator = false;

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
                        return 'Please enter a name.';
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
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter a password.';
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
                      if (!canSubmit) return;
                      //Hide keyboard
                      FocusScope.of(context).unfocus();
                      canSubmit = false;
                      if (key.currentState.validate()) {
                        setState(() {
                          showProcessIndicator = true;
                        });
                        bool success = await widget.serverAPI.signIn(
                            this.name,
                            this.password,
                            resultTextKey.currentState);
                        setState(() {
                          showProcessIndicator = false;
                        });
                        if(success){
                          Navigator.pushReplacement(
                              context,
                              new MaterialPageRoute(
                                  builder: (BuildContext context) => new MainMenu(
                                    serverAPI: widget.serverAPI,
                                  ))
                          );
                        }
                      }
                      canSubmit = true;
                    },
                  ),
                ),
                Visibility(
                  child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Center(child: CircularProgressIndicator())),
                  visible: showProcessIndicator,
                ),
                Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: ChangingText(
                        key: this.resultTextKey,
                        text: '',
                      ),
                    )),
                Visibility(
                  visible: canSubmit,
                  child: Center(
                    child: InkWell(
                      child: Text('or click here to sign up.'),
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            new MaterialPageRoute(
                                builder: (BuildContext context) =>
                                new SignUpForm(
                                  serverAPI: widget.serverAPI,
                                )));
                      },
                    )
                )),
              ],
            )),
        backgroundColor: Theme.of(context).backgroundColor
    );
  }
}
