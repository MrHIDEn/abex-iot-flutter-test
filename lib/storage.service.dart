import 'package:localstorage/localstorage.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'json.type.dart';

class StorageService {
  StorageService._internal();

  static final StorageService _singleton = StorageService._internal();

  factory StorageService() {
    _singleton.test();
    return _singleton;
  }

  static const _storageKey = "abex_iot_app";
  static const _configKey = "config";
  final _k = Key.fromUtf8("JdhrrQVs9y9IyjXJVsK5D1I7A7FNoPOR");
  final _i = IV.fromLength(16);
  late final Encrypter _encrypter = Encrypter(AES(_singleton._k));

  final LocalStorage _storage = LocalStorage(_storageKey);
  // final prefs = await SharedPreferences.getInstance();

  void test() {
    // // _storage.deleteItem(_configKey);
    // final JsonDynamic config = {
    //   "broker": "192.168.233.23",
    //   "clientId": "abex-mobile-1",
    //   "username": "abex-mobile-1",
    //   "password": "Q9SWWyPwYX2ebKSu"
    // };
    // saveConfig(config);
    // final config2 = readConfig();
    // print(config2);
    // print(config2);
  }

  void saveConfig(JsonDynamic config) {
    save(_configKey, config);
  }

  JsonDynamic readConfig() {
    var config = read(_configKey);
    if (config == null) {
      // config = {
      //   "broker": "",
      //   "clientId": "",
      //   "username": "",
      //   "password": ""
      // };
      config = {
        "broker": "192.168.233.23",
        "clientId": "abex-mobile-1",
        "username": "abex-mobile-1",
        "password": "Q9SWWyPwYX2ebKSu"
      };
      saveConfig(config);
    }
    return config;
  }

  void save(String key, JsonDynamic map) {
    final json = jsonEncode(map);
    final base16 = _encrypter.encrypt(json, iv: _i).base16;
    _storage.setItem(key, base16); // await?
  }

  JsonDynamic? read(String key) {
    final base16 = _storage.getItem(key);
    if (base16 == null) return null;
    try {
      final json = _encrypter.decrypt16(base16, iv: _i);
      return jsonDecode(json);
    } on Exception {
      return null;
    }
  }
}
