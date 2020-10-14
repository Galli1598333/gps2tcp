import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock/wakelock.dart';

/// A widget that will request and display position updates
/// using the device's location services.
class PositionUpdates extends StatefulWidget {
  PositionUpdates(
      {Key key,
      @required this.ip,
      @required this.port,
      @required this.frequency})
      : super(key: key);

  final String ip;
  final int port;
  final int frequency;

  @override
  _PositionUpdatesState createState() => _PositionUpdatesState();
}

class _PositionUpdatesState extends State<PositionUpdates>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Position> _positionStreamSubscription;
  final _positions = <Position>[];
  AnimationController _animationController;
  Timer _timer;
  bool _send;
  Socket _socket;

  initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    connectTCP().then((result) {
      setState(() {
        _socket = result;
        _socket.listen((List<int> event) {
          print(utf8.decode(event));
        });
        _send = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Transmission'),
        ),
        body: FutureBuilder<LocationPermission>(
            future: checkPermission(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data == LocationPermission.denied) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                      children: [
                          Text('Request location permission',
                              style: const TextStyle(
                                fontSize: 32.0,
                              ),
                              textAlign: TextAlign.center),
                        SizedBox(height: 15),
                          Text(
                              'Access to the device\'s location has been denied, please request permissions before continuing',
                              style: const TextStyle(fontSize: 16.0),
                              textAlign: TextAlign.center),
                        SizedBox(height: 15),
                      ],
                    ),
                        )),
                    RaisedButton(
                      child: const Text('Request permission'),
                      onPressed: () => requestPermission()
                          .then((status) => setState(_positions.clear)),
                    ),
                  ],
                );
              }

              if (snapshot.data == LocationPermission.deniedForever) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                  children: [
                      Text('Access to location permanently denied',
                          style: const TextStyle(
                            fontSize: 32.0,
                          ),
                          textAlign: TextAlign.center),
                    SizedBox(height: 15),
                      Text(
                          'Allow access to the location services for this App using the device settings.',
                          style: const TextStyle(fontSize: 16.0),
                          textAlign: TextAlign.center),
                    SizedBox(height: 15),
                  ],
                ),
                    ));
              }

              return _buildListView();
            }));
  }

  Widget _buildListView() {
    final listItems = <Widget>[
      ListTile(
        title: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RaisedButton(
              child: _buildButtonText(),
              color: _determineButtonColor(),
              padding: const EdgeInsets.all(8.0),
              onPressed: _toggleListening,
            ),
            _send ?? false
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.green),
                  )
                : Container(),
            RaisedButton(
              child: Row(
                children: [
                  Text('Clear '),
                  Icon(Icons.clear_all),
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              onPressed: () => setState(_positions.clear),
            ),
          ],
        ),
      ),
    ];

    listItems.addAll(_positions.map((position) {
      return ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              '${position.latitude}, ${position.longitude}',
              style: const TextStyle(fontSize: 16.0),
            ),
            Text(
              position.timestamp.toString(),
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      );
    }));

    return ListView(
      children: listItems,
    );
  }

  void startTimer(int frequency) {
    Duration amount = Duration(milliseconds: frequency);
    _timer = new Timer.periodic(
      amount,
      (Timer timer) => setState(
        () {
          _send = true;
          timer.cancel();
        },
      ),
    );
  }

  Future<Socket> connectTCP() async {
    Socket newSocket = await Socket.connect(widget.ip, widget.port);
    debugPrint('Step 2, fetch data');
    return newSocket;
  }

  bool _isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription.isPaused);

  Widget _buildButtonText() {
    return Row(
      children: [
        Text(
          _isListening() ? 'Stop ' : 'Start ',
          style: TextStyle(color: Colors.white),
        ),
        AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _animationController,
          color: Colors.white,
        ),
      ],
    );
  }

  Color _determineButtonColor() {
    return _isListening() ? Colors.red : Colors.green;
  }

  Widget _buildButtonIcon() {
    return Text(_isListening() ? 'Stop ' : 'Start ');
  }

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      final positionStream = getPositionStream();
      _positionStreamSubscription = positionStream.handleError((error) {
        _positionStreamSubscription.cancel();
        _positionStreamSubscription = null;
      }).listen((position) => setState(() {
            if (_send) {
              _send = false;
              _positions.add(position);
              _socket.write(position.toJson());
              startTimer(widget.frequency);
            }
          }));
      _positionStreamSubscription.pause();
    }

    setState(() {
      if (_positionStreamSubscription.isPaused) {
        _animationController.forward();
        _positionStreamSubscription.resume();
        Wakelock.enable();
        startTimer(widget.frequency);
        print('enabled');
      } else {
        _animationController.reverse();
        _positionStreamSubscription.pause();
        Wakelock.disable();
        _send = false;
        _timer.cancel();
        print('disabled');
      }
    });
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription.cancel();
      _positionStreamSubscription = null;
    }
    if (_timer != null) {
      _timer.cancel();
    }
    _socket.close();
    super.dispose();
  }
}
