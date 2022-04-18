import 'dart:async';
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
    // var topic = "abex-basen-1/r/all";
    // var json =
    //     '{"params":{"vw0":237,"vw2":364,"v100":1,"v101":1,"v102":1,"v103":1}}';
    // _singleton.mqttService
    //     .emit("received", null, {"topic": topic, "json": json});
    // print(_singleton.getGetTemperaturaWodyC());
    // print(_singleton.getGetTemperaturaOtoczeniaC());
    // print(_singleton.getSetOswietlenie());
    // _singleton.setSetTWodyTestC(23.4);
    // _singleton.setSetTOtoczTestC(28.9);
    // _singleton.setSetPWodyTestCm(180);
    // _singleton.setSetSendAll();
    // _singleton.setSetSendAll();
    // _singleton.setSetSendAll();
    return _singleton;
  }

  final MqttService mqttService = MqttService()
    ..on("ready", null, (ev, context) {
      _singleton.ready();
    })
    ..on("received", null, (ev, context) {
      _singleton.received(ev);
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

  double getGetTemperaturaWodyC() => params[VMap.GetTWody]! / 10.0;

  double getGetTemperaturaOtoczeniaC() => params[VMap.GetTOtocz]! / 10.0;

  double getGetPoziomWodyCm() => params[VMap.GetPWody]!.toDouble();

  double getSetTemperaturaWodyC() => params[VMap.SetTWody]! / 10.0;

  double getSetTemperaturaOtoczeniaC() => params[VMap.SetTOtocz]! / 10.0;

  bool getSetOswietlenie() => params[VMap.SetOswietlenie]! == 1;

  bool getSetRoleta() => params[VMap.SetRoleta]! == 1;

  bool getSetFiltr() => params[VMap.SetFiltr]! == 1;

  bool getSetAtrakcja() => params[VMap.SetAtrakcja]! == 1;

  bool getSetGrzanie() => params[VMap.SetGrzanie]! == 1;

  bool getGetOswietlenie() => params[VMap.GetOswietlenie]! == 1;

  bool getGetRoleta() => params[VMap.GetRoleta]! == 1;

  bool getGetFiltr() => params[VMap.GetFiltr]! == 1;

  bool getGetAtrakcja() => params[VMap.GetAtrakcja]! == 1;

  bool getGetGrzanie() => params[VMap.GetGrzanie]! == 1;

  setSetTemperaturaWodyC(double value) =>
      publishDouble(VMap.SetTWody, 10.0 * value);

  setSetTemperaturaOtoczeniaC(double value) =>
      publishDouble(VMap.SetTOtocz, 10.0 * value);

  setSetSendAll() {
    final rng = Random();
    final value = rng.nextInt(65535);
    final chain = ChainMap()..addInt(VMap.SetSendAll, value);
    publishChain(chain);
    //TEST
    setSetOswietlenieH();
  }

  setSetOswietlenieH() => publishBool(VMap.SetOswietlenie, true);

  setSetRoletaH() => publishBool(VMap.SetRoleta, true);

  setSetFiltrH() => publishBool(VMap.SetFiltr, true);

  setSetAtrakcjaH() => publishBool(VMap.SetAtrakcja, true);

  setSetGrzanieH() => publishBool(VMap.SetGrzanie, true);

  // TESTY
  setSetTWodyTestC(double value) =>
      publishDouble(VMap.SetPWodyTest, (10.0 * value + 650) / 1.25);

  setSetTOtoczTestC(double value) =>
      publishDouble(VMap.SetPWodyTest, (10.0 * value + 526) / 1.13);

  setSetPWodyTestCm(double value) =>
      publishDouble(VMap.SetPWodyTest, (value + 50) / 0.25);

  void ready() {
    print("//FS ready");
    setSetSendAll();
  }

  void received(Event ev) {
    final data = ev.eventData as Map<String, String>;
    // final topic = data["topic"] ?? "";
    // final json = data["json"] ?? "";
    // print("//FS topic: $topic, json: '$json'");
    print("//FS received");
    final json = data["json"] ?? "";
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
      // emit("error", null, "Receive failed"); //ograc to?
    }
    clearAllSetFlags();
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
    Timer(const Duration(milliseconds: 4000), () {
      print("//FS clear flags, ${chain.length}");
      publishChain(chain);
    });
  }

  void publishBool(String vmapKey, bool val) {
    final chain = ChainMap()..addBool(vmapKey, val);
    publishChain(chain);
  }

  void publishInt(String vmapKey, int val) {
    final chain = ChainMap()..addInt(vmapKey, val);
    publishChain(chain);
  }

  void publishDouble(String vmapKey, double val) {
    final chain = ChainMap()..addDouble(vmapKey, val);
    publishChain(chain);
  }

  // void publishMap(Json map) {
  //   if (map.isNotEmpty) {
  //     map = {"params": map};
  //     mqttService.publishMap(map);
  //   }
  // }

  void publishChain(ChainMap chain) {
    if (chain.isNotEmpty) {
      var map = {"params": chain.map()};
      mqttService.publishMap(map);
    }
  }
}

/* NOTE
Example JSON frame
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
