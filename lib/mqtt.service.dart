import 'dart:async';
import 'dart:io';
import 'dart:convert';

// https://pub.dev/packages/eventify/install
import 'package:typed_data/typed_data.dart' as typed;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:eventify/eventify.dart';
import 'json.type.dart';

class MqttService extends EventEmitter {
  MqttService._internal();

  static final MqttService _singleton = MqttService._internal();

  factory MqttService({
    String? broker,
    String? clientId,
    String? username,
    String? password,
  }) {
    if (broker != null) _singleton.broker = broker;
    if (clientId != null) _singleton.clientId = clientId;
    if (username != null) _singleton.username = username;
    if (password != null) _singleton.password = password;

    _singleton._reconnect();

    return _singleton;
  }

  @override
  String toString() => "$MqttService $broker";

  // Config
  String broker = "";
  String clientId = "";
  String username = "";
  String password = "";
  final subscribeTopic = "abex-basen-1/r/all";
  final publishTopic = "abex-basen-1/w/all";
  MqttClient? client;

  bool get connected =>
      client?.connectionStatus!.state == MqttConnectionState.connected;

  Future<bool> _reconnect() async {
    client?.disconnect();
    return await connect();
  }

  Future<bool> connect() async {
    if (connected) {
      // Already connected
      return await _reconnect();
    } else {
      client = await _connect();
      return client != null;
    }
  }

  Future<MqttClient?> _connect() async {
    if (broker == "" || clientId == "") {
      emit("error", null, "Provide broker url and client id.");
      return null;
    }

    // Connect
    MqttClient? client = MqttClient(broker, clientId)
      ..autoReconnect = true
      ..setProtocolV311()
      ..logging(on: true)
      ..keepAlivePeriod = 60
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected;
      // ..onUnsubscribed = _onUnsubscribed    // @MqttServerClient
      // ..onSubscribeFail = _onSubscribeFail; // @MqttServerClient

    // /// If the mqtt connection lost
    // /// MqttBroker publish this message on this topic.
    // final mqttMsg = MqttConnectMessage()
    //     .withWillMessage('connection-failed')
    //     .withWillTopic('willTopic')
    //     .startClean()
    //     .withWillQos(MqttQos.atLeastOnce)
    //     .withWillTopic('failed');
    // client.connectionMessage = mqttMsg;

    // Last will
    // final MqttConnectMessage connMess = MqttConnectMessage()
    //     .authenticateAs(connectJson['username'], connectJson['key'])
    //     .withClientIdentifier('myClientID')
    //     .keepAliveFor(60) // Must agree with the keep alive set above or not set
    //     .withWillTopic(
    //     'willtopic') // If you set this you must set a will message
    //     .withWillMessage('My Will message')
    //     .startClean() // Non persistent session for testing
    //     .withWillQos(MqttQos.atMostOnce);
    // log.info('Adafruit client connecting....');
    // client.connectionMessage = connMess;

    try {
      await client.connect(username, password);
      // } on Exception catch (e) {
    } on Exception {
      client.disconnect();
      client = null;
      return null;
    }

    /// Check we are connected
    if (connected) {
      // Client connected
    } else {
      client.disconnect();
      client = null;
    }

    return client;
  }

  void _onSubscribed(String topic) {
    emit("info", null, "Ready");
  }

  void _onDisconnected() {
    emit("info", null, "Disconnected");
    client?.disconnect();
  }

  void _onConnected() async {
    await subscribe();
    emit("info", null, "Connected");
  }

  void _onAutoReconnect() {
    emit("info", null, "Reconnect");
  }

  void _onAutoReconnected() async {
    await subscribe();
    emit("info", null, "Reconnected");
  }

  void _onUnsubscribed() {
    emit("info", null, "Unsubscribed");
  }

  void _onSubscribeFail() {
    emit("error", null, "Subscribe fail");
  }

  Future subscribe() async {
    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    client?.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? mrmList) {
      // final msg = msgList.where((msg) => msg.topic == subscribeTopic).toList();
      final mrm = mrmList?[0];
      final topic = mrm?.topic;
      final mqttMessage = mrm?.payload as MqttPublishMessage;
      final json =
          MqttPublishPayload.bytesToStringAsString(mqttMessage.payload.message);
      emit("received", null , {"topic": topic, "json": json});
    });

    client?.subscribe(subscribeTopic, MqttQos.atMostOnce);
    return true;
  }

  void publishMap(Json map) {
    publishJson(jsonEncode(map));
  }

  void publishJson(String json) {
    if (!connected) {
      emit("info", null, "Connected");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(json);
    client?.publishMessage(publishTopic, MqttQos.atMostOnce, builder.payload!);
  }

  // TEST
  int increment(int v) {
    return v + 2;
  }
}

/* NOTE
https://github.com/BitKnitting/flutter_adafruit_mqtt/blob/master/lib/mqtt_stream.dart

https://stackoverflow.com/questions/70710328/im-having-trouble-connecting-to-mqtt-in-flutter
 */
