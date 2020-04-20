import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static Future<int> getLocalMessagesCount(codename) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final file = File('$path/vaults.json');
    if(!await file.exists()) return 0;
    final fileVaults = json.decode(await file.readAsString());
    var res = 0;
    fileVaults.forEach((v){
      if(v['codename'] == codename){
        res = v['messagesCount'];
      }
    });
    return res;
  }

  static void saveVaults(vaults) async {
    vaults.forEach((v){
      updateVault(v, false);
    });
  }

  static Future<void> updateVault(vault, updateCount) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path;
    final file = File('$path/vaults.json');
    var fileVaults = <dynamic>[];
    if(await file.exists()) fileVaults = json.decode(await file.readAsString());
    var found = false;
    fileVaults.forEach((v){
      if(v['codename'] == vault.codename){
        found = true;
        v['accessToken'] = vault.accessToken;
        if(updateCount) {
          v['messagesCount'] = vault.newestIndex;
          v['notifiedMessagesCount'] = vault.newestIndex;
        }
      }
    });

    if(!found){
      final map = {
        'codename': vault.codename,
        'accessToken': vault.accessToken,
        'messagesCount': vault.newestIndex,
        'notifiedMessagesCount': vault.newestIndex
      };
      fileVaults.add(map);
    }
    file.writeAsString(json.encode(fileVaults));
    debugPrint('Saved vaults JSON to $path');
  }
}