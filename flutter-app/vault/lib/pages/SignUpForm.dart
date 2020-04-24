import 'package:flutter/material.dart';
import 'package:vault/widgets/ChangingText.dart';
import 'package:vault/pages/MainMenu.dart';
import 'package:vault/utils/ServerAPI.dart';
import 'package:vault/pages/SignInForm.dart';

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
  String passwordConfirm;
  bool canSubmit = true;
  bool showProcessIndicator = false;

  @override
  Widget build(BuildContext context) {
    widget.serverAPI.setContext(context);
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
                      if (value != this.passwordConfirm) {
                        return 'Passwords do not match.';
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
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter password again.';
                      }
                      if (value != this.password) {
                        return 'Password do not match.';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      this.passwordConfirm = value;
                    },
                    style: Theme.of(context).textTheme.body1,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
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
                      'Sign up',
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
                        bool success = await widget.serverAPI.signUp(this.name,
                            this.password, resultTextKey.currentState);
                        setState(() {
                          showProcessIndicator = false;
                        });
                        if (success) {
                          Navigator.pushReplacement(
                              context,
                              new MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      new MainMenu(
                                        serverAPI: widget.serverAPI,
                                      )));
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
                      child: Text('or click here to sign in.'),
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            new MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    new SignInForm(
                                      serverAPI: widget.serverAPI,
                                    )));
                      },
                    ))),
              ],
            )),
        backgroundColor: Theme.of(context).backgroundColor);
  }
}
