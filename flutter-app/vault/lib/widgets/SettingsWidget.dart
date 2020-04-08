import 'package:flutter/material.dart';
import 'package:vault/utils/Classes.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({Key key, this.vault}) : super(key: key);
  final Vault vault;

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
                        text: vault.codename,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' and name '),
                    TextSpan(
                        text: vault.name,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '. Currently, there '),
                    TextSpan(text: vault.keys.length == 1 ? 'is ' : 'are '),
                    TextSpan(
                        text: vault.keys.length.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: vault.keys.length == 1 ? ' key' : ' keys'),
                    TextSpan(text: ' issued. This vault contains '),
                    TextSpan(
                        text: vault.getTotalMessageCount().toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: vault.getTotalMessageCount() == 1
                            ? ' message.'
                            : ' messages.'),
                  ]),
            ),
          ),
          Text('Members:', style: Theme.of(context).textTheme.subhead,),
          ListView.builder(
            shrinkWrap: true,
            itemCount: vault.keys.length,
            itemBuilder: (context, i) => buildRow(i),
          )
        ],
      ),
    );
  }

  buildRow(i){
    return Text(vault.keys[i]);
  }
}
