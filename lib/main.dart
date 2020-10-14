import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:gps2tcp/positionUpdates.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gps2tcp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'gps2tcp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          //mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            FormBuilder(
              key: _fbKey,
              initialValue: {
                'ip': '10.0.2.2',
                'port': '1213',
                'frequency': '1000',
              },
              autovalidate: true,
              child: Column(
                children: <Widget>[
                  SizedBox(height: 15),
                  FormBuilderTextField(
                    attribute: "ip",
                    decoration: InputDecoration(labelText: "IP address"),
                    keyboardType: TextInputType.numberWithOptions(),
                    validators: [
                      FormBuilderValidators.IP(),
                      FormBuilderValidators.required(),
                    ],
                  ),
                  SizedBox(height: 15),
                  FormBuilderTextField(
                    attribute: "port",
                    decoration: InputDecoration(labelText: "Port"),
                    keyboardType: TextInputType.number,
                    validators: [
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.min(1024),
                      FormBuilderValidators.max(49151),
                      FormBuilderValidators.required(),
                    ],
                  ),
                  SizedBox(height: 15),
                  FormBuilderTextField(
                    attribute: "frequency",
                    decoration: InputDecoration(labelText: "Frequency (millisec)"),
                    keyboardType: TextInputType.numberWithOptions(),
                    validators: [
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.min(100),

                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: MaterialButton(
                    child: Text("Reset all"),
                    onPressed: () {
                      _fbKey.currentState.reset();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_fbKey.currentState.saveAndValidate()) {
            print(_fbKey.currentState.value);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PositionUpdates(
                  ip: _fbKey.currentState.value['ip'],
                  port: int.parse(_fbKey.currentState.value['port']),
                  frequency: int.parse(_fbKey.currentState.value['frequency']),
              )),
            );
          }
        },
        tooltip: 'Next',
        child: Icon(Icons.navigate_next),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
