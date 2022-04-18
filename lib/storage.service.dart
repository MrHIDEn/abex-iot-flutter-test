import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:async';
import 'json.type.dart';

class StorageService {
  StorageService._internal();

  static final StorageService _singleton = StorageService._internal();

  factory StorageService() {
    _singleton.test();
    return _singleton;
  }

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // static const _storageKey = "abex_iot_app";
  static const _configKey = "config";
  final _k = Key.fromUtf8("JdhrrQVs9y9IyjXJVsK5D1I7A7FNoPOR");
  final _i = IV.fromLength(16);
  late final Encrypter _encrypter = Encrypter(AES(_singleton._k));

  Future<void> test() async {

    // final config0 = await readConfig();
    // print('//SS config0 $config0');

    // final config1 = await read(_configKey);
    // print(config1);
    //
    // final success = await remove(_configKey);
    //
    // final config2 = await read(_configKey);
    // print(config2);
    //
    // final config3 = await readConfig();
    // print(config3);
    //
    //
    // final config4 = await read(_configKey);
    // print(config4);
    //
    // // // _storage.deleteItem(_configKey);
    final JsonDynamic config = {
      "broker": "192.168.233.23",
      "clientId": "abex-mobile-1",
      "username": "abex-mobile-1",
      "password": "Q9SWWyPwYX2ebKSu"
    };
    await saveConfig(config);
    //
    // final config5 = await readConfig();
    // print('//SS config5 $config5');
    // print(config5);
  }

  Future<void> saveConfig(JsonDynamic config) async {
    await save(_configKey, config);
  }

  Future<JsonDynamic> readConfig() async {
    var config = await read(_configKey);
    if (config == null) {
      config = {
        "broker": "",
        "clientId": "",
        "username": "",
        "password": ""
      };
      // config = {
      //   "broker": "192.168.233.23",
      //   "clientId": "abex-mobile-1",
      //   "username": "abex-mobile-1",
      //   "password": "Q9SWWyPwYX2ebKSu"
      // };
      await saveConfig(config);
    }
    return config;
  }

  Future<bool> remove(String key) async {
    final SharedPreferences prefs = await _prefs;
    return await prefs.remove(key);
  }

  Future<void> save(String key, JsonDynamic map) async {
    final SharedPreferences prefs = await _prefs;
    final json = jsonEncode(map);
    final base16 = _encrypter.encrypt(json, iv: _i).base16;
    // _storage.setItem(key, base16); // await?
    await prefs.setString(key, base16);
  }

  Future<JsonDynamic?> read(String key) async {
    final SharedPreferences prefs = await _prefs;
    // final base16 = _storage.getItem(key);
    final base16 = prefs.getString(key);
    if (base16 == null) return null;
    try {
      final json = _encrypter.decrypt16(base16, iv: _i);
      return jsonDecode(json);
    } on Exception {
      return null;
    }
  }
}
