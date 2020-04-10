import 'package:flutter/material.dart';
import 'package:vault/utils/Classes.dart';
import 'package:vault/widgets/ChangingText.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key key, this.vault}) : super(key: key);
  final Vault vault;
  @override
  State<StatefulWidget> createState() {
    return SettingsWidgetState();
  }
}

class SettingsWidgetState extends State<SettingsWidget> {
  final addingStatusKey = GlobalKey<ChangingTextState>();
  String newMemberName = '';
  bool addingMember = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: RichText(
              text: TextSpan(
                  style: Theme.of(context).textTheme.body1,
                  children: <TextSpan>[
                    TextSpan(text: 'This vault has codename '),
                    TextSpan(
                        text: widget.vault.codename,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' and name '),
                    TextSpan(
                        text: widget.vault.name,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '. Currently, there '),
                    TextSpan(
                        text: widget.vault.keys.length == 1 ? 'is ' : 'are '),
                    TextSpan(
                        text: widget.vault.keys.length.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: widget.vault.keys.length == 1 ? ' key' : ' keys'),
                    TextSpan(text: ' issued. This vault contains '),
                    TextSpan(
                        text: widget.vault.getTotalMessageCount().toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: widget.vault.getTotalMessageCount() == 1
                            ? ' message.'
                            : ' messages.'),
                  ]),
            ),
          ),
          Text(
            'Members:',
            style: Theme.of(context).textTheme.subhead,
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.vault.keys.length,
            itemBuilder: (context, i) => buildRow(i),
          ),
          Visibility(
            visible: !addingMember,
            child: Form(
              child: Column(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.all(10),
                      child: TextFormField(
                          onChanged: (value) => newMemberName = value,
                          decoration:
                              InputDecoration(hintText: 'Enter new member.'))),
                  RaisedButton(
                      onPressed: () async {
                        setState(() {
                          addingMember = true;
                        });
                        await widget.vault.addMember(
                            newMemberName, addingStatusKey.currentState);
                        setState(() {
                          addingMember = false;
                        });
                      },
                      color: Colors.grey[700],
                      child: Text(
                        'Add',
                        style: Theme.of(context).textTheme.body1,
                      )),
                  Center(
                      child: Text(
                          'This action cannot be undone. There is no going back after clicking the "Add" button. The user will gain access to all messages in this vault.'))
                ],
              ),
            ),
          ),
          Visibility(
            visible: addingMember,
            child: Center(child: CircularProgressIndicator()),
          ),
          Center(
              child: Padding(
                  padding: EdgeInsets.all(5),
                  child: ChangingText(
                    key: addingStatusKey,
                    text: '',
                  )))
        ],
      ),
    );
  }

  buildRow(i) {
    return Text(widget.vault.keys[i]);
  }
}
