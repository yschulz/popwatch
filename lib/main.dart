import 'dart:async';

import 'package:flutter/material.dart';


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

  int milliseconds = 0;
  int seconds = 0;
  int minutes = 0;
  
  String digitMilliseconds = '000';
  String digitSeconds = '00';
  String digitMinutes = '00';

  Timer? timer;
  bool started = false;
  List logs = [];

  bool _armed = false;
  double _sensitivity = 100.0;

  void stop() {
    timer!.cancel();
    setState(() {
      started = false;
    });
  }

  void reset() {
    logCycle();
    timer!.cancel();
    setState(() {
      milliseconds = 0;
      seconds = 0;
      minutes = 0;

      digitMilliseconds = '000';
      digitSeconds = '00';
      digitMinutes = '00';

      started = false;
    });
  }

  void logCycle() {
    String cycle = "$digitMinutes:$digitSeconds:$digitMilliseconds";
    setState(() {
      logs.add(cycle);
    });
  }

  void deleteElementCycle(index) {
    setState(() {
      logs.removeAt(index);
    });
  }

  void start() {
    started = true;
    timer = Timer.periodic(Duration(milliseconds: 1), (timer) {
      int localMilliseconds = milliseconds + 1;
      int localSeconds = seconds;
      int localMinutes = minutes;

      if(localMilliseconds > 999) {
        if(localSeconds > 59) {
          localMinutes++;
          localSeconds = 0;
        }
        else {
          localSeconds++;
          localMilliseconds = 0;
        }
      }

      setState(() {
        milliseconds = localMilliseconds;
        seconds = localSeconds;
        minutes = localMinutes;

        if(milliseconds >= 10) {
          if(milliseconds >= 100) {
            digitMilliseconds = "$milliseconds";
          }
          else {
            digitMilliseconds = "0$milliseconds";
          }
        }
        else {
          digitMilliseconds = "00$milliseconds";
        }
        digitSeconds = (seconds >= 10) ?"$seconds":"0$seconds";
        digitMinutes = (minutes >= 10) ?"$minutes":"0$minutes";
          
      });
     });
  }

  void arming() {
    if(_armed) {
      _armed = false;
    }
    else {
      _armed = true;
    }
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
                  Expanded(
                    child: RawMaterialButton(
                      onPressed: arming,
                      shape: const StadiumBorder(side: BorderSide(color: Color.fromARGB(255, 3, 70, 9))),
                      child: const Text('Arm',
                        style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))
                      ),
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
                      onPressed: () { (!started) ? start() : stop();},
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
                  child: Text('$digitMinutes:$digitSeconds.$digitMilliseconds',
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
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cycle ${index+1}', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                          Text("${logs[index]}", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                          IconButton(onPressed: () { setState(() {
                            logs.removeAt(index);
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
