import 'package:flutter/material.dart';
import 'package:vault/MainMenu.dart';
import 'package:vault/ServerAPI.dart';

import 'ChangingText.dart';

class NewVaultMenu extends StatefulWidget {
  const NewVaultMenu(
      {Key key, this.serverApi})
      : super(key : key);
  final ServerAPI serverApi;
  @override
  State<StatefulWidget> createState() {
    return NewVaultMenuState();
  }
}

class NewVaultMenuState extends State<NewVaultMenu> {
  final formKey = GlobalKey<FormState>();
  final resultTextKey = GlobalKey<ChangingTextState>();
  String codename;
  String name;
  bool showProcessIndicator = false;
  bool canSubmit = true;
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
                  onChanged: (value) => codename = value,
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
                  onChanged: (value) => name = value,
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
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      if(formKey.currentState.validate() && canSubmit){
                        canSubmit = false;
                        setState(() {
                          showProcessIndicator = true;
                        });
                        resultTextKey.currentState.setText('NotImplemented');
                        final success = await widget.serverApi.createVault(
                            codename, name,
                            resultTextKey.currentState);
                        setState(() {
                          showProcessIndicator = false;
                        });
                        if(success){
                          //Pop new vault menu
                          Navigator.pop(context);

                          //Replace main menu
                          Navigator.pushReplacement(context,
                          MaterialPageRoute(
                            builder: (context) => MainMenu(
                              serverAPI: widget.serverApi,
                            )
                          ));
                        } else {
                          canSubmit = true;
                        }
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
