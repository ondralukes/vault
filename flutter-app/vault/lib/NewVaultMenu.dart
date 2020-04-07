import 'package:flutter/material.dart';

import 'ChangingText.dart';

class NewVaultMenu extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NewVaultMenuState();
  }
}

class NewVaultMenuState extends State<NewVaultMenu> {
  final formKey = GlobalKey<FormState>();
  final resultTextKey = GlobalKey<ChangingTextState>();
  bool showProcessIndicator = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New vault'),
      ),
      body: Form(
          key: formKey,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  decoration: InputDecoration(hintText: 'Codename'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Enter a codename.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Text('Codename is NOT encrypted.'),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  decoration: InputDecoration(hintText: 'Name'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Enter a name.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Text('Name is encrypted.'),
              ),
              Padding(
                  padding: EdgeInsets.all(10),
                  child: RaisedButton(
                    color: Colors.grey[700],
                    onPressed: () {
                      if(formKey.currentState.validate()){
                        setState(() {
                          showProcessIndicator = true;
                        });
                        resultTextKey.currentState.setText('NotImplemented');
                        throw('NotImplemented');
                      }
                    },
                    child: Text(
                      'Create',
                      style: Theme.of(context).textTheme.body1,
                    ),
                  )),
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
            ],
          )),
      backgroundColor: Theme.of(context).backgroundColor,
    );
  }
}
