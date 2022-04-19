import 'package:flutter/material.dart';

import 'frame.service.dart';
import 'mqtt.service.dart';
import 'storage.service.dart';

void main() {
  print("//Main");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // const MyApp({Key? key}) : super(key: key);
  MyApp({Key? key}) : super(key: key) {
    /// Start MQTT with config
    startMqttClient();
  }

  void startMqttClient() async {
    // final store = StorageService();
    final config = await StorageService().readConfig();
    print('//MA config $config');
    MqttService(
      broker: config["broker"],
      clientId: config["clientId"],
      username: config["username"],
      password: config["password"],
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print("//MA build()");
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  //const
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final _frame = FrameService();

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _storage = StorageService();
  final _frame = FrameService();

  // Fields
  int _counter = 0;
  double getTWody = 0.0;
  double getTOtocz = 0.0;
  double getPWody = 0.0;
  double setTWody = 0.0;
  double setTOtocz = 0.0;
  bool setOswietlenie = false;
  bool setRoleta = false;
  bool setFiltr = false;
  bool setAtrakcja = false;
  bool setGrzanie = false;
  bool getOswietlenie = false;
  bool getRoleta = false;
  bool getFiltr = false;
  bool getAtrakcja = false;
  bool getGrzanie = false;

  // MqttService? _mqtt;
  // final _mqtt = MqttService(
  //     broker: "192.168.233.23",
  //     clientId: "abex-mobile-1",
  //     username: "abex-mobile-1",
  //     password: "Q9SWWyPwYX2ebKSu");

  // _MyHomePageState() {
  //   final config = _storage.readConfig();
  //   _mqtt = MqttService(
  //     broker: config["broker"],
  //     clientId: config["clientId"],
  //     username: config["username"],
  //     password: config["password"],
  //   );
  // }
  _MyHomePageState() {
    // _frame.on("update", null, (ev, context) {
    //   print('//MH update');
    //   print(ev);
    //   print(context);
    //   // setState(() {
    //   //   // Put your codes here.
    //   // });
    // });
    _frame.onUpdated = onUpdated;
  }

  void onUpdated() {
    print('//MH on updated');
    setState(() {
      getTWody = _frame.getGetTemperaturaWodyC();
      getTOtocz = _frame.getGetTemperaturaOtoczeniaC();
      getPWody = _frame.getGetPoziomWodyCm();
      setTWody = _frame.getSetTemperaturaWodyC();
      setTOtocz = _frame.getSetTemperaturaOtoczeniaC();
      setOswietlenie = _frame.getSetOswietlenie();
      setRoleta = _frame.getSetRoleta();
      setFiltr = _frame.getSetFiltr();
      setAtrakcja = _frame.getSetAtrakcja();
      setGrzanie = _frame.getSetGrzanie();
      getOswietlenie = _frame.getGetOswietlenie();
      getRoleta = _frame.getGetRoleta();
      getFiltr = _frame.getGetFiltr();
      getAtrakcja = _frame.getGetAtrakcja();
      getGrzanie = _frame.getGetGrzanie();
    });
  }

  void _refresh() {
    _frame.refresh(0);
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      // _counter++;
      _counter = _frame.refresh(_counter);
      // _tWodyC = _frame.getGetTemperaturaWodyC();
    });
  }

  @override
  Widget build(BuildContext context) {
    print("//MH build");
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // child: B
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //--
            Text(
              'Temp. Wody: $getTWody,',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Temp. Otocz: $getTOtocz,',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Poziom. Wody: $getPWody,',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            //--
            Text(
              'Nas. Temp. Wody: $setTWody,',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Nas. Temp. Otocz: $setTOtocz,',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            //--
            Text(
              'Oswietlenie: ${getOswietlenie ? "ON" : "OFF"},',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Roleta: ${getRoleta ? "ON" : "OFF"},',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Filtr: ${getFiltr ? "ON" : "OFF"},',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Atrakcja: ${getAtrakcja ? "ON" : "OFF"},',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Grzanie: ${getGrzanie ? "ON" : "OFF"},',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            //--
            ElevatedButton(
              onPressed: () {
                _frame.refresh(0);
              },
              child: const Text('Refresh', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(onPrimary: Colors.green),
            ),
            //--
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme
                  .of(context)
                  .textTheme
                  .headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
