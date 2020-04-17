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
        'accessToken': v.accessToken
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
}