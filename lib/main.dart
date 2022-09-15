import 'dart:async';
import 'package:noise_meter/noise_meter.dart';
import 'package:flutter/material.dart';
import 'package:popwatch/gauge/gauge_driver.dart';
import 'package:popwatch/gauge/animated_gauge.dart';


void main(List<String> args) {
  runApp(PopWatch());

}

class PopWatch extends StatelessWidget {
  const PopWatch({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PopWatchHome(),
    );
  }
}


class PopWatchHome extends StatefulWidget {
  PopWatchHome({super.key});

  @override
  _PopWatchHomeState createState() => _PopWatchHomeState();
}

class _PopWatchHomeState extends State<PopWatchHome> {

  int _milliseconds = 0;
  int _seconds = 0;
  int _minutes = 0;
  bool _locked = false;

  String _digitMilliseconds = '00';
  String _digitSeconds = '00';
  String _digitMinutes = '00';

  Timer? _timer;
  bool _started = false;
  List _logs = [];
  List _textController = [];

  bool _armed = false;
  String _armedText = 'Arm';

  double _sensitivity = 70.0;
  double _meanDecibel = 0.0;
  double _maxDecibel = 70.0;

  bool _isRecording = false;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  late NoiseMeter _noiseMeter;

  GaugeDriver _driver = GaugeDriver();
  final Key animatedKey = const Key('animatedKey');

  @override
  void initState() {
    super.initState();
    _noiseMeter = new NoiseMeter(onError);
    _driver.listen((x) => setState(() { }) );
  }
  
  @override
  void dispose() {
    _noiseSubscription?.cancel();
    super.dispose();
  }

  void lockTimer() {
    _locked = true;
    Timer lockTimer = Timer(const Duration(seconds: 1), () {
      setState(() {_locked = false; });
    },);
  }

  void onData(NoiseReading noiseReading) {
    setState(() {
      if (!_isRecording) {
        _isRecording = true;
      }
      _meanDecibel = noiseReading.meanDecibel;
      if(_meanDecibel > _sensitivity){
        // if(_seconds != _lockAtSecond) {
        if(!_locked) {
          if(!_started) {
            timerStart();
          } 
          else  {
            timerStop();
          }
          lockTimer();
        }
      }
      if(_meanDecibel > _maxDecibel) {
        _maxDecibel = _meanDecibel;
      }
    });
    _driver.drive((_meanDecibel / _maxDecibel).abs());
    print(noiseReading.toString());
    print(_locked);
    
  }

  void onError(Object error) {
    print(error.toString());
    _isRecording = false;
  }

  void noiseMeterStart() async {
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
    } catch (err) {
      print(err);
    }
  }

  void noiseMeterStop() async {
    try {
      if (_noiseSubscription != null) {
        _noiseSubscription!.cancel();
        _noiseSubscription = null;
      }
      setState(() {
        _isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
    _driver.drive(0.0);
  }

  void timerStop() {
    _timer!.cancel();
    setState(() {
      _started = false;
    });
  }

  void reset() {
    logCycle();
    _timer!.cancel();
    setState(() {
      _milliseconds = 0;
      _seconds = 0;
      _minutes = 0;

      _digitMilliseconds = '00';
      _digitSeconds = '00';
      _digitMinutes = '00';

      _started = false;
    });
  }

  void logCycle() {
    String cycle = "$_digitMinutes:$_digitSeconds:$_digitMilliseconds";
    setState(() {
      _logs.add(cycle);
      _textController.add(TextEditingController());
    });
  }

  void timerStart() {
    _started = true;
    _timer = Timer.periodic(Duration(milliseconds: 10), (_timer) {
      int localMilliseconds =_milliseconds + 10;
      int localSeconds = _seconds;
      int localMinutes = _minutes;

      if(localMilliseconds > 990) {
        if(localSeconds > 58) {
          localMinutes++;
          localSeconds = 0;
        } else {
          localSeconds++;
        }
        localMilliseconds = 0;
      }

      setState(() {
        _milliseconds = localMilliseconds;
        _seconds = localSeconds;
        _minutes = localMinutes;

        _digitMilliseconds = (_milliseconds ~/ 10 >= 10) ?"${_milliseconds ~/ 10}":"0${_milliseconds ~/ 10}";
        _digitSeconds = (_seconds >= 10) ?"$_seconds":"0$_seconds";
        _digitMinutes = (_minutes >= 10) ?"$_minutes":"0$_minutes";
          
      });
     });
  }

  void arming(dummy) {
    setState(() {
      if(_armed) {
        _armed = false;
        _armedText = 'Arm';
        noiseMeterStop();
        timerStop();
      } else {
        _armed = true;
        _armedText = 'Armed!';
        noiseMeterStart();
      }      
    });
  }

  void setSensitivity(sensitivity) {
    setState(() {
      _sensitivity = sensitivity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PopWatch'),), 
      backgroundColor: Color.fromARGB(255, 31, 31, 31),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(child: ToggleButtons(
                      constraints: BoxConstraints.expand(width: 110.0, height: 40.0 ),
                      children: [Text(_armedText)],
                      isSelected: [_armed],
                      onPressed: arming,
                      selectedBorderColor: Color.fromARGB(255, 255, 0, 0),
                      borderRadius: BorderRadius.circular(8.0),
                      borderColor: Color.fromARGB(255, 0, 255, 0),
                      color: Color.fromARGB(255, 255, 255, 255),
                      selectedColor: Color.fromARGB(255, 255, 255, 255),
                      fillColor: Color.fromARGB(75, 255, 0, 0),
                    ),
                  ),
                  const SizedBox(width: 10.0,),
                  Expanded(
                    child: RawMaterialButton(
                      onPressed: reset,
                      shape: const StadiumBorder(side: BorderSide(color: Color.fromARGB(255, 48, 75, 165))),
                      child: const Text('Reset',
                        style: TextStyle(color:  Color.fromARGB(255, 255, 255, 255))
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0,),
                  Expanded(
                    child: RawMaterialButton(
                      onPressed: () { (!_started) ? timerStart() : timerStop();},
                      shape: const StadiumBorder(side: BorderSide(color: Color.fromARGB(255, 48, 75, 165))),
                      child: const Text('Start',
                        style: TextStyle(color:  Color.fromARGB(255, 255, 255, 255))
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 100.0,
                decoration: BoxDecoration(
                  color: Color.fromARGB(127, 122, 122, 122),
                  borderRadius: BorderRadius.circular(6.0)
                ),
                child: Center(
                  child: Text('$_digitMinutes:$_digitSeconds.$_digitMilliseconds',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 75.0,
                      fontWeight: FontWeight.w600
                      ),
                  ),
                ),
              ),
              Container(
                height: 70.0,
                decoration: BoxDecoration(
                  color: Color.fromARGB(127, 122, 122, 122),
                  borderRadius: BorderRadius.circular(6.0)
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 6.0),
                      Text('Sensitivity',
                        style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                      Slider(min: 0.0, max: _maxDecibel, value: _sensitivity, onChanged: setSensitivity)
                    ],
                  ),
                ),
              ),
              Container(
                height: 70.0,
                decoration: BoxDecoration(
                  color: Color.fromARGB(127, 122, 122, 122),
                  borderRadius: BorderRadius.circular(6.0)
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 6.0),
                      Text('Decibel',
                        style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                      AnimatedGauge(key: animatedKey, driver: _driver),
                    ],
                  ),
                ),
              ),
              Container(
                height: 250.0,
                decoration: BoxDecoration(
                  color: Color.fromARGB(127, 122, 122, 122),
                  borderRadius: BorderRadius.circular(6.0)
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 1.0, 5.0, 1.0),
                      child: Row(
                        children: [
                          Text('Cycle ${index+1}', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: SizedBox(height: 25.0, 
                              child: TextField(
                                controller: _textController[index],
                                style: TextStyle(
                                  color: Colors.white
                                ),
                                maxLength: 30,
                                decoration: InputDecoration(
                                  counterText: "",
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(50)
                                  ),
                                  filled: true,
                                  fillColor: Color.fromARGB(255, 41, 41, 41),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.0),
                          Text("${_logs[index]}", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                          IconButton(onPressed: () { setState(() {
                            _logs.removeAt(index);
                            _textController[index].clear();
                            _textController.removeAt(index);
                          });}, icon: Icon(Icons.cancel)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ), 
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // Try running your application with "flutter run". You'll see the
//         // application has a blue toolbar. Then, without quitting the app, try
//         // changing the primarySwatch below to Colors.green and then invoke
//         // "hot reload" (press "r" in the console where you ran "flutter run",
//         // or simply save your changes to "hot reload" in a Flutter IDE).
//         // Notice that the counter didn't reset back to zero; the application
//         // is not restarted.
//         primarySwatch: Colors.blue,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Invoke "debug painting" (press "p" in the console, choose the
//           // "Toggle Debug Paint" action from the Flutter Inspector in Android
//           // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//           // to see the wireframe for each widget.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headline4,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
