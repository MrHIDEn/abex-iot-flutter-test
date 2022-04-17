import 'dart:convert';
import 'dart:math';

import 'package:eventify/eventify.dart';

import 'chain-map.class.dart';
import 'json.type.dart';
import 'mqtt.service.dart';
import 'vmap.translation.dart';

//TODO zrobic to jako service?
class FrameService {
  FrameService._internal();

  static final FrameService _singleton = FrameService._internal();

  factory FrameService() {
    var topic = "topic";
    var json = '{"params":{"vw0":65,"v100":1}}';
    _singleton.mqttService
        .emit("received", null, {"topic": topic, "json": json});
    _singleton.setTWodyTest = 23.4;
    _singleton.setTOtoczTest = 28.9;
    _singleton.setPWodyTest = 180;
    _singleton.setSendAll();
    return _singleton;
  }

  final MqttService mqttService = MqttService()
    ..on("received", null, (ev, context) {
      _singleton.received(ev, context);
    });

  int? id;
  String? version;
  String? method;

  JsonInt params = {
    VMap.GetTWody: 0, //       R
    VMap.GetTOtocz: 0, //      R
    VMap.GetPWody: 0, //       R

    VMap.SetTWody: 0, //       RW
    VMap.SetTOtocz: 0, //      RW
    VMap.SetSendAll: 0, //     RW

    VMap.SetOswietlenie: 0, // RW
    VMap.SetRoleta: 0, //      RW
    VMap.SetFiltr: 0, //       RW
    VMap.SetAtrakcja: 0, //    RW
    VMap.SetGrzanie: 0, //     RW

    VMap.GetOswietlenie: 0, // R
    VMap.GetRoleta: 0, //      R
    VMap.GetFiltr: 0, //       R
    VMap.GetAtrakcja: 0, //    R
    VMap.GetGrzanie: 0, //     R

    VMap.SetTWodyTest: 0, //  R
    VMap.SetTOtoczTest: 0, // R
    VMap.SetPWodyTest: 0, //  R
  };

  double get getTemperaturaWodyC => params[VMap.GetTWody]! / 10.0;

  double get getTemperaturaOtoczeniaC => params[VMap.GetTOtocz]! / 10.0;

  double get getPoziomWodyCm => params[VMap.GetPWody]!.toDouble();

  double get setTemperaturaWodyC => params[VMap.SetTWody]! / 10.0;

  double get setTemperaturaOtoczeniaC => params[VMap.SetTOtocz]! / 10.0;

  bool get setOswietlenie => params[VMap.SetOswietlenie]! == 1;

  bool get setRoleta => params[VMap.SetRoleta]! == 1;

  bool get setFiltr => params[VMap.SetFiltr]! == 1;

  bool get setAtrakcja => params[VMap.SetAtrakcja]! == 1;

  bool get setGrzanie => params[VMap.SetGrzanie]! == 1;

  bool get getOswietlenie => params[VMap.GetOswietlenie]! == 1;

  bool get getRoleta => params[VMap.GetRoleta]! == 1;

  bool get getFiltr => params[VMap.GetFiltr]! == 1;

  bool get getAtrakcja => params[VMap.GetAtrakcja]! == 1;

  bool get getGrzanie => params[VMap.GetGrzanie]! == 1;

  set setTemperaturaWodyC(double value) {}

  set setTemperaturaOtoczeniaC(double value) {}

  setSendAll() {
    final rng = Random();
    final value = rng.nextInt(65535);
    final chain = ChainMap()..addInt(VMap.SetSendAll, value);
    publishChain(chain);
  }

  set setOswietlenie(bool value) {}

  set setRoleta(bool value) {}

  set setFiltr(bool value) {}

  set setAtrakcja(bool value) {}

  set setGrzanie(bool value) {}

  // TESTY
  set setTWodyTest(double value) {
    final val = (10.0 * value + 650) ~/ 1.25;
    final chain = ChainMap()..addInt(VMap.SetTWodyTest, val);
    publishChain(chain);
  }

  set setTOtoczTest(double value) {
    final val = (10.0 * value + 526) ~/ 1.13;
    final chain = ChainMap()..addInt(VMap.SetTOtoczTest, val);
    publishChain(chain);
  }

  set setPWodyTest(double value) {
    final val = (value + 50) ~/ 0.25;
    final chain = ChainMap()..addInt(VMap.SetPWodyTest, val);
    publishChain(chain);
  }

  // VMap.SetTWodyTest: 0, //  R
  // VMap.SetTOtoczTest: 0, // R
  // VMap.SetPWodyTest: 0, //  R

  void received(Event ev, Object? context) {
    final data = ev.eventData as Map<String, String>;
    final topic = data["topic"] ?? "";
    final json = data["json"] ?? "";
    print("topic: $topic, json: '$json'");
    _singleton.update(json);
  }

  void update(String json) {
    try {
      final paramsMap = (jsonDecode(json))["params"] as Json;
      print(paramsMap);
      paramsMap.forEach((key, val) {
        // Update only expected values
        if (params.containsKey(key)) {
          params[key] = val;
        }
      });
      print(params);
    } on Exception catch (e) {
      print(e);
    }
  }

  void clearAllSetFlags() {
    // Send 0 to all when 1 set flags [100-104]
    final chain = ChainMap(params)
      ..clearFlags([
        VMap.SetOswietlenie, // monostable
        VMap.SetRoleta, //      monostable
        VMap.SetFiltr, //       monostable
        VMap.SetAtrakcja, //    monostable
        // VMap.SetGrzanie, //  bistable
      ]);
    publishChain(chain);
  }

  void publishChain(ChainMap chain) {
    var msg = {"params": chain.map()};
    print(msg);
    // Publish msg
    mqttService.publishMap(msg);
  }

// void publishMap(JsonInt map) {
//   var msg = {"params": map};
//   // Publish msg
//   mqttService.publishMap(msg);
// }
}
/*
{
        "version":      "1.0",
        "params":       {
                "vw0":  64886,
                "vw2":  65010,
                "vw4":  65486,
                "vw6":  2900,
                "vw8":  150,
                "vw12": 150,
                "v100": 0,
                "v101": 0,
                "v102": 0,
                "v103": 0,
                "v104": 0,
                "v110": 0,
                "v111": 1,
                "v112": 0,
                "v113": 0,
                "v114": 0
        },
        "id":   31359,
        "method":       "thing.event.property.post"
}
 */
