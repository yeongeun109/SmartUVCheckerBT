import 'dart:async';
import 'dart:convert';
import 'package:convert_hex/convert_hex.dart';
import 'package:geniuvc/uvDose.dart';
import 'package:geniuvc/uvIntensity.dart';
import 'package:geniuvc/uvcSafe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'uvIndex.dart';

class Navigation extends StatefulWidget {
  final String deviceid;
  final BluetoothDevice device;

  const Navigation({Key key, @required this.deviceid, this.device})
      : super(key: key);

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String CHARACTERISTIC_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  Stream<List<int>> stream;
  StreamController _ctrl;
  StreamSubscription subscription;
  bool isReady;
  String band;
  int battery;
  List<int> arr;

  @override
  void initState() {
    super.initState();
    //checkConnectedDevices();
    connectToDevice();
    isReady = false;
  }

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  checkConnectedDevices() async {
    var connectedDevices = await FlutterBlue.instance.connectedDevices;
    print(connectedDevices);
    if (connectedDevices != null) {
      disconnectFromDevice();
      connectToDevice();
    } else
      connectToDevice();
    connectedDevices = await FlutterBlue.instance.connectedDevices;
    print(connectedDevices);
  }

  connectToDevice() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    await widget.device.connect();
    discoverServices();
  }

  disconnectFromDevice() {
    widget.device.disconnect();
  }

  discoverServices() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;
            int cnt = 0;
            subscription = stream.asBroadcastStream().listen(null);
            subscription.onData((value) {
              if (value.toString() != null) {
                print("listen stream : $value");

                cnt++;
                print(cnt);
                if (cnt == 2) {
                  subscription.cancel();
                  print('cancel and disconnect');
                  disconnectFromDevice();
                  String a = utf8.decode(value);
                  print(a);
                  List<String> arr = a.split(' ');

                  if (Hex.decode(arr[6]) == 1)
                    band = 'UVA';
                  else if (Hex.decode(arr[6]) == 2)
                    band = 'UVB';
                  else if (Hex.decode(arr[6]) == 3)
                    band = 'UVC';
                  else if (Hex.decode(arr[6]) == 4)
                    band = 'UVV';
                  else if (Hex.decode(arr[6]) == 5)
                    band = 'VGR';
                  else if (Hex.decode(arr[6]) == 6)
                    band = 'VBL';
                  else if (Hex.decode(arr[6]) == 0)
                    band = '0';
                  else
                    band = 'UNKNOWN';

                  battery = Hex.decode(arr[0]);

                  setState(() {
                    isReady = true;
                  });
                }

                print(band);
                print(battery);

              }
            });
            //_ctrl.close();
            /*setState(() {
              isReady = true;
            });*/
          }
        });
      }
    });
  }

  _Pop() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image(
                image: AssetImage('images/genuv_logo_small_white.png'),
                width: 100,
              ),
              SizedBox(width: 30),
              Expanded(
                  flex: 1, child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Smart UV Checker 2'),
                    ],
                  )),
            ],
          ),
          backgroundColor: Color(0xFFef7f11),
        ),
        body: Column(
          children: <Widget>[
            Text('(Device id) ${widget.deviceid}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            isReady ? Text('CONNECTED') : Text('NOT CONNECTED'),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Center(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: 200,
                          height: 60,
                          child: RaisedButton(
                            child: Text(
                              'UV INTENSITY',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                                side: BorderSide(
                                    color: Color(0x335f3206), width: 2)),
                            onPressed: () {
                              if(isReady == true && band != '0') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            uvIntensity(
                                              device: widget.device,
                                              band: band,
                                              battery: battery,
                                              //controller: controller,
                                            )
                                    ));
                              }
                              else{
                                if(isReady != true){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('not connected yet'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                                else if(band == '0'){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('스위치 Setting을 확인해주세요.'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                              }
                              //}
                            },
                              color: Color(0xFFef7f11)
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: 200,
                          height: 60,
                          child: RaisedButton(
                            child: Text(
                              'UV DOSE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                                side: BorderSide(
                                    color: Color(0x335f3206), width: 2)),
                            onPressed: () {
                              if(isReady == true && band != '0') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            uvDose(
                                                device: widget.device,
                                                band: band,
                                                //controller: controller,
                                            )));
                              }
                              else{
                                if(isReady != true){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('not connected yet'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                                else if(band == '0'){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('스위치 Setting을 확인해주세요.'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                              }
                              //}
                            },
                            color: Color(0xFFef7f11),
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: 200,
                          height: 60,
                          child: RaisedButton(
                            child: Text(
                              'UV INDEX',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                                side: BorderSide(
                                    color: Color(0x335f3206), width: 2)),
                            onPressed: () {
                              if(isReady == true && band == '0') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            uvIndex(device: widget.device)));
                              }
                              else{
                                if(isReady != true){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('not connected yet'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                                else if(band != '0'){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('스위치 Setting을 확인해주세요.'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                              }
                            },
                            color: Color(0xFFef7f11),
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: 200,
                          height: 60,
                          child: RaisedButton(
                            child: Text(
                              'UVC SAFE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                                side: BorderSide(
                                    color: Color(0x335f3206), width: 2)),
                            onPressed: () {
                              if(isReady == true && band == 'UVC') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            uvcSafe(device: widget.device)));
                              }
                              else{
                                if(isReady != true){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('not connected yet'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                                else if(band != 'UVC'){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AlertDialog(
                                            content: Text('스위치 Setting을 확인해주세요.'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: new Text('close')),
                                            ],
                                          )));
                                }
                              }
                            },
                            color: Color(0xFFef7f11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}