import 'dart:async';
import 'dart:convert';

// https://pub.dev/packages/eventify/install
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

    // _singleton._timer ??= // 20, 30s?
    //     Timer.periodic(const Duration(seconds: 5), _singleton.checkConnect);

    final bool reconnect = broker != null ||
        clientId != null ||
        username != null ||
        password != null;
    _singleton._reconnect(reconnect);

    return _singleton;
  }

  @override
  String toString() => '$MqttService "$broker", "$clientId"';

  /// Config
  String broker = "";
  String clientId = "";
  String username = "";
  String password = "";
  final subscribeTopic = "abex-basen-1/r/all";
  final publishTopic = "abex-basen-1/w/all";
  MqttClient? _client;

  // bool get connected =>
  // _client?.connectionStatus!.state == MqttConnectionState.connected;
  bool get _accepted =>
      _client?.connectionStatus!.returnCode ==
      MqttConnectReturnCode.connectionAccepted;

  // Timer? _timer;

  // bool _preConnecting = false;

  // Future checkConnect(Timer timer) async {
  //   if (!_preConnecting && !_accepted) {
  //     _preConnecting = true;
  //     print('//MQ try connect, client: "${_client != null}"');
  //     // _client?.disconnect();
  //     // await _reconnect(true);
  //     // await _connect();
  //     _preConnecting = false;
  //   }
  // }

  Future<void> _reconnect(bool reconnect) async {
    print("//MQ _reconnect: $reconnect");
    if (reconnect) {
      _client?.disconnect();
      // _client = null;
      await _connect();
    }
  }

  bool _connecting = false;

  Future<void> _connect() async {
    if (broker == "" || clientId == "") {
      emit("error", null, "Provide broker url and client id.");
      return;
    }
    if (username == "" || password == "") {
      emit("error", null, "Provide user mane and password.");
      return;
    }

    if (_connecting) {
      return;
    }
    _connecting = true;

    /// Create connection
    try {
      _client = MqttServerClient(broker, clientId)

        /// Configs
        // ..logging(on: true)
        ..onAutoReconnect = _onAutoReconnect
        ..onAutoReconnected = _onAutoReconnected
        ..onUnsubscribed = _onUnsubscribed
        ..autoReconnect = true
        ..setProtocolV311()
        ..keepAlivePeriod = 60
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..onSubscribeFail = _onSubscribeFail;
    } on Exception catch (e) {
      // } on Exception {
      emit("error", null, "Establish connection failed");
      print(e);
      _connecting = false;
      return;
    }

    /// Connect
    try {
      final status = await _client?.connect(username, password);
      print('//MQ accepted "$_accepted", ${status?.state.name}');
    } on Exception catch (e) {
      // } on Exception {
      emit("error", null, "Connect failed");
      print(e);
      _client?.disconnect();
      _client = null;
    }

    _connecting = false;
    return;
  }

  void _onSubscribed(String topic) {
    print("//MQ on subscribed: $topic");
    // emit("subscribed", null, topic);
    emit("ready");
  }

  void _onDisconnected() {
    print("//MQ on disconnected");
    // _listener?.cancel();
    emit("info", null, "disconnected");
  }

  void _onConnected() async {
    print("//MQ on connected");
    await subscribe();
    emit("info", null, "connected");
  }

  void _onAutoReconnect() {
    print("//MQ on auto reconnect");
    emit("reconnect");
  }

  void _onAutoReconnected() {
    print("//MQ on auto reconnected");
    // await subscribe(); //??
    emit("auto-reconnect");
  }

  void _onUnsubscribed(String? topic) {
    print('//MQ on unsubscribed "$topic');
    emit("unsubscribed", null, topic ?? "");
  }

  void _onSubscribeFail(String topic) {
    print('//MQ subscribe fail "$topic"');
    emit("error", null, "Subscribe failed");
    _client?.disconnect();
  }

  StreamSubscription? _listener;

  Future subscribe() async {
    print("//MQ subscribe");

    //_listener?.cancel();

    //TODO moze wyjac to wyzej bo nie trzea restartowac tego chyba ze client sie zmienia
    //server ma chyba problemy z subscrpcjami !!
    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    _listener = _client?.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> msgList) {
      try {
        final msg = msgList.first;

        final message = (msg.payload as MqttPublishMessage).payload.message;
        final json = MqttPublishPayload.bytesToStringAsString(message);

        emit("received", null, {"topic": msg.topic, "json": json});
      } on Exception catch (e) {
        // } on Exception {
        print(e);
        emit("error", null, "Receive failed");
      }
    });

    _client?.subscribe(subscribeTopic, MqttQos.atMostOnce);
    return true;
  }

  void publishMap(Json map) {
    if (!_accepted) return;
    print("//MQ publishMap, $map");
    publishJson(jsonEncode(map));
  }

  void publishJson(String json) {
    if (!_accepted) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(json);
    _client?.publishMessage(publishTopic, MqttQos.atMostOnce, builder.payload!);
  }
}

/* NOTE
https://github.com/BitKnitting/flutter_adafruit_mqtt/blob/master/lib/mqtt_stream.dart

https://stackoverflow.com/questions/70710328/im-having-trouble-connecting-to-mqtt-in-flutter
 */
