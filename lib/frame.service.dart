import 'dart:convert';
import 'dart:math';
// import 'dart:async';

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
    VMap.getTWody: 0, //       R
    VMap.getTOtocz: 0, //      R
    VMap.getPWody: 0, //       R

    VMap.setTWody: 0, //       RW
    VMap.setTOtocz: 0, //      RW
    VMap.setSendAll: 0, //     RW

    VMap.setOswietlenie: 0, // RW
    VMap.setRoleta: 0, //      RW
    VMap.setFiltr: 0, //       RW
    VMap.setAtrakcja: 0, //    RW
    VMap.setGrzanie: 0, //     RW

    VMap.getOswietlenie: 0, // R
    VMap.getRoleta: 0, //      R
    VMap.getFiltr: 0, //       R
    VMap.getAtrakcja: 0, //    R
    VMap.getGrzanie: 0, //     R

    VMap.setTWodyTest: 0, //  R
    VMap.setTOtoczTest: 0, // R
    VMap.setPWodyTest: 0, //  R
  };

  double getGetTemperaturaWodyC() => params[VMap.getTWody]! / 10.0;

  double getGetTemperaturaOtoczeniaC() => params[VMap.getTOtocz]! / 10.0;

  double getGetPoziomWodyCm() => params[VMap.getPWody]!.toDouble();

  double getSetTemperaturaWodyC() => params[VMap.setTWody]! / 10.0;

  double getSetTemperaturaOtoczeniaC() => params[VMap.setTOtocz]! / 10.0;

  bool getSetOswietlenie() => params[VMap.setOswietlenie]! == 1;

  bool getSetRoleta() => params[VMap.setRoleta]! == 1;

  bool getSetFiltr() => params[VMap.setFiltr]! == 1;

  bool getSetAtrakcja() => params[VMap.setAtrakcja]! == 1;

  bool getSetGrzanie() => params[VMap.setGrzanie]! == 1;

  bool getGetOswietlenie() => params[VMap.getOswietlenie]! == 1;

  bool getGetRoleta() => params[VMap.getRoleta]! == 1;

  bool getGetFiltr() => params[VMap.getFiltr]! == 1;

  bool getGetAtrakcja() => params[VMap.getAtrakcja]! == 1;

  bool getGetGrzanie() => params[VMap.getGrzanie]! == 1;

  setSetTemperaturaWodyC(double value) =>
      publishDouble(VMap.setTWody, 10.0 * value);

  setSetTemperaturaOtoczeniaC(double value) =>
      publishDouble(VMap.setTOtocz, 10.0 * value);

  setSetSendAll() {
    final rng = Random();
    final value = rng.nextInt(65535);
    final chain = ChainMap()..addInt(VMap.setSendAll, value);
    publishChain(chain);
  }

  setSetOswietlenieH() => publishBool(VMap.setOswietlenie, true);

  setSetRoletaH() => publishBool(VMap.setRoleta, true);

  setSetFiltrH() => publishBool(VMap.setFiltr, true);

  setSetAtrakcjaH() => publishBool(VMap.setAtrakcja, true);

  setSetGrzanieH() => publishBool(VMap.setGrzanie, true);

  // TESTY
  setSetTWodyTestC(double value) =>
      publishDouble(VMap.setTWodyTest, (10.0 * value + 650) / 1.25 + .5);

  setSetTOtoczTestC(double value) =>
      publishDouble(VMap.setTOtoczTest, (10.0 * value + 526) / 1.13 + .5);

  setSetPWodyTestCm(double value) =>
      publishDouble(VMap.setPWodyTest, (value + 50) / 0.25 + .5);

  void ready() {
    print("//FS ready");
    setSetSendAll();
    //TEST
    setSetOswietlenieH();
    _singleton.setSetTWodyTestC(23.4);
    _singleton.setSetTOtoczTestC(34.5);
    _singleton.setSetPWodyTestCm(181);
  }

  void received(Event ev) {
    final data = ev.eventData as Map<String, JsonDynamic>;
    // final map = data["map"] ?? {};
    // print("//FS topic: $topic, json: '$json'");
    final topic = data["topic"] ?? "";
    print("//FS received().topic $topic");
    final map = data["map"] ?? {} as JsonDynamic;
    _singleton.update(map);
  }

  void update(JsonDynamic map) {
    try {
      final paramsMap = (map["params"] ?? {}) as JsonDynamic;
      print("//FS update().params $paramsMap");
      paramsMap.forEach((key, val) {
        /// Update only expected values
        if (params.containsKey(key)) params[key] = val;
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
        VMap.setOswietlenie, // monostable
        VMap.setRoleta, //      monostable
        VMap.setFiltr, //       monostable
        VMap.setAtrakcja, //    monostable
        // VMap.SetGrzanie, //  bistable
      ]);
    // Timer(const Duration(milliseconds: 4000), () {
    print("//FS clear flags, ${chain.length}");
    publishChain(chain);
    // });
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

  //TODO flaga wymuszania i wymuszanie danych w petli az nie zejdzie

  void publishChain(ChainMap chain) {
    if (chain.isNotEmpty) {
      // final rng = Random();
      // final id = rng.nextInt(65535);
      // final map = {"params": chain.map(), "id": id, "version": "1.0"};
      final map = {"params": chain.map()};
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
