import 'dart:convert';

class ChainMap {
  final Map<String, int> _map = {};
  Map<String, int> _params = {};

  ChainMap([Map<String, int>? params]) {
    _params = params ?? {};
  }

  void addBool(String key, bool flag) {
    _map[key] = flag ? 1 : 0;
  }

  void addInt(String key, int val) {
    _map[key] = val;
  }

  void addDouble(String key, double val) {
    _map[key] = (val * 10.0).toInt();
  }

  void clearFlag(String key) {
    if (_params[key] == 1) {
      _map[key] = 0;
    }
  }

  void clearFlags(List<String> keys) {
    for (final key in keys) {
      if (_params[key] == 1) {
        _map[key] = 0;
      }
    }
  }

  void attach(List<String> keys) {
    for (final key in keys) {
      _map[key] = _params[key] ?? 0;
    }
  }

  Map<String, int> map() {
    return _map;
  }

  String toJson() {
    return jsonEncode(_map);
  }
}