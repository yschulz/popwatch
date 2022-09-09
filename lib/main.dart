import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mic_stream/mic_stream.dart';

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
  
  String _digitMilliseconds = '00';
  String _digitSeconds = '00';
  String _digitMinutes = '00';

  Timer? _timer;
  bool _started = false;
  List _logs = [];
  List _textController = [];

  bool _armed = false;
  String _armedText = 'Arm';

  Stream? _stream;
  late StreamSubscription _listener;
  List<int>? _currentSamples = [];
  List<int> _visibleSamples = [];
  int? _localMax;
  int? _localMin;
  bool _isRecording = false;
  late bool _isActive = false;
  late int _bytesPerSample;
  late int _samplesPerSecond;

  Future<bool> _startListening() async {
    if(_isRecording) return false;

    MicStream.shouldRequestPermission(true);

    _stream = await MicStream.microphone(
      audioSource: AudioSource.DEFAULT,
      sampleRate: 44100,
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );
    setState(() {
      _isRecording = true;
    });
    _visibleSamples = [];
    _listener = _stream!.listen(_calculateIntensitySamples);
    return true;
  }

  void _calculateIntensitySamples(samples) {
    _currentSamples ??= [];
    int currentSample = 0;
    eachWithIndex(samples, (i, int sample) {
      currentSample += sample;
      if ((i % _bytesPerSample) == _bytesPerSample-1) {
        _currentSamples!.add(currentSample);
        currentSample = 0;
      }
    });

    if (_currentSamples!.length >= _samplesPerSecond/10) {
      _visibleSamples.add(_currentSamples!.map((i) => i).toList().reduce((a, b) => a+b));
      _localMax ??= _visibleSamples.last;
      _localMin ??= _visibleSamples.last;
      _localMax = max(_localMax!, _visibleSamples.last);
      _localMin = min(_localMin!, _visibleSamples.last);
      _currentSamples = [];
      setState(() {  });
    }
  }

  bool _stopListening() {
    if(!_isRecording) return false;
    _listener.cancel();

    setState(() {
      _isRecording = false;
      _currentSamples = null;
    });
    return true;
  }

  double _sensitivity = 100.0;

  void stop() {
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

  void start() {
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
      } else {
        _armed = true;
        _armedText = 'Armed!';
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
                      onPressed: () { (!_started) ? start() : stop();},
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
                      Slider(min: 0.0, max: 100.0, value: _sensitivity, onChanged: setSensitivity)
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
                      Text('Gain',
                        style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                      ),
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

Iterable<T> eachWithIndex<E, T>(
    Iterable<T> items, E Function(int index, T item) f) {
  var index = 0;

  for (final item in items) {
    f(index, item);
    index = index + 1;
  }

  return items;
}

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
