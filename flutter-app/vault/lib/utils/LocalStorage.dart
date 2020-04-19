import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static void saveVaults(vaults) async {
    final list = List<Map>();
    vaults.forEach((v){
      final map = {
        'codename': v.codename,
        'accessToken': v.accessToken,
        'messagesCount': v.newestIndex
      };
      list.add(map);
    });
    final string = json.encode(list);
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final file = File('$path/vaults.json');
    file.writeAsString(string);
    debugPrint('Saved vaults JSON to $path');
  }

  static void updateVault(vault) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final file = File('$path/vaults.json');
    final fileVaults = json.decode(await file.readAsString());
    final list = List<Map>();
    fileVaults.forEach((v){
      if(v['codename'] == vault.codename){
        v['accessToken'] = vault.accessToken;
        v['messagesCount'] = vault.newestIndex;
      }
    });
    file.writeAsString(json.encode(fileVaults));
    debugPrint('Saved vaults JSON to $path');
  }
}