import 'package:flutter/material.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        body: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(25),
                child: Text(
                    'Vault',
                  style: Theme.of(context).textTheme.headline,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  style: Theme.of(context).textTheme.body1,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    prefixIcon: Icon(
                        Icons.perm_identity,
                        color: Theme.of(context).primaryColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor
                        )
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor
                        )
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  style: Theme.of(context).textTheme.body1,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(
                      Icons.vpn_key,
                      color: Theme.of(context).primaryColor
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor
                        )
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor
                        )
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: RaisedButton(
                  child: Text(
                      'Sign in',
                       style: Theme.of(context).textTheme.body1,
                  ),
                ),
              )
            ],
          ),
        ),
        backgroundColor: Colors.grey[800]
    );
  }
}