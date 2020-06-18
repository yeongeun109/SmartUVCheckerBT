import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:convert_hex/convert_hex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';


class uvIntensity extends StatefulWidget {
  final BluetoothDevice device;
  final String band;
  final int battery;
  final PageController controller;

  const uvIntensity({Key key, this.device, this.band, this.battery, this.controller})
      : super(key: key);

  @override
  _uvIntensityState createState() => _uvIntensityState();
}

class _uvIntensityState extends State<uvIntensity> {
  final String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String CHARACTERISTIC_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  bool isReady, connectionFlag = false, _isbuttonStart = true;
  Stream<List<int>> stream;

  double min = 3100, max = 0, avg = 0, val_sum = 0;
  String min_string, max_string, avg_string;
  int val_cnt = 0;
  List<String> powerVal_list = [' UV Power(mW/cm²)'];
  List<String> datetime_list = ['Date/Time'];
  List<String> min_list = [' MIN.(mW/cm²)'];
  List<String> max_list = [' MAX.(mW/cm²)'];
  List<String> avg_list = [' AVG.(mW/cm²)'];

  List<List<dynamic>> rows = List<List<dynamic>>();
  static GlobalKey previewContainer = new GlobalKey();

  @override
  void initState() {
    super.initState();
    checkConnectedDevices();
    isReady = false;
    getPermission();
  }

  getPermission() async{
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    print(statuses[Permission.storage]);
  }

  checkConnectedDevices() async {
    var connectedDevices = await FlutterBlue.instance.connectedDevices;
    print(connectedDevices);
    if (connectedDevices != null) disconnectFromDevice();
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
    if (widget.device == null) {
      _Pop();
      return;
    }
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

            setState(() {
              isReady = true;
            });
          }
        });
      }
    });
  }

  Future<bool> _onWillPop() {
    disconnectFromDevice();
    print('disconnect');
    Navigator.of(context).pop(true);
  }

  _Pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int> dataFromDevice) {
    String a = utf8.decode(dataFromDevice);
    print(a);
    String result;
    double adc_val;
    if (a.length > 0) {
      List<String> arr = a.split(' ');
      if((Hex.decode(arr[1]) > 3100) && (Hex.decode(arr[2]) > 3100) && (Hex.decode(arr[3]) > 3100) && (Hex.decode(arr[4]) > 3100))
        adc_val = 0;
      if (Hex.decode(arr[1]) < 3100)
        adc_val = ((Hex.decode(arr[1]) / 3100) * 0.1);
      else if (Hex.decode(arr[2]) < 3100)
        adc_val = (Hex.decode(arr[2]) / 3100);
      else if (Hex.decode(arr[3]) < 3100)
        adc_val = (Hex.decode(arr[3]) / 3100 * 10);
      else if (Hex.decode(arr[4]) < 3100)
        adc_val = (Hex.decode(arr[4]) / 3100 * 100);
    }
    if (adc_val < min) {
      min = adc_val;
    }
    if (adc_val > max) {
      max = adc_val;
    }
    val_cnt++;
    val_sum += adc_val;
    avg = val_sum / val_cnt;

    min_string = min.toString();
    if (min_string.length > 6) {
      min_string = min_string.substring(0, 6);
      min_list.add(min_string);
    }
    else
      min_list.add(min_string);

    max_string = max.toString();
    if (max_string.length > 6) {
      max_string = max_string.substring(0, 6);
      max_list.add(max_string);
    }
    else
      max_list.add(max_string);

    avg_string = avg.toString();
    if (avg_string.length > 6) {
      avg_string = avg_string.substring(0, 6);
      avg_list.add(avg_string);
    }
    else
      avg_list.add(avg_string);
    //print('min = ${min}, max = ${max}, avg = ${avg}, adc_val = ${adc_val}');

    result = adc_val.toString();

    if (result.length > 6) {
      result = result.substring(0, 6);
      powerVal_list.add(result);
    } else {
      powerVal_list.add(result);
    }

    print('powerVal : $powerVal_list');
    print('max : $max_list');
    print('min : $min_list');
    print('avg : $avg_list');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: RepaintBoundary(
            key: previewContainer,
            //controller: screenshotController,
            child: Scaffold(
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
                            Text('UV Intensity'),
                          ],
                        )),
                  ],
                ),
                backgroundColor: Color(0xFFef7f11),
              ),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                    children: <Widget>[
                      Container(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'Battery : ${widget.battery}',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                            ),
                          )
                        ],
                      )),
                      SizedBox(height: 30),
                      Container(
                          child: Row(
                        children: <Widget>[
                          Text(
                            'UV Band : ${widget.band}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              //fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      )),
                      SizedBox(height: 30),
                      Text(
                        'UV Power',
                        style: TextStyle(
                          color: Colors.grey[600],
                          //fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                          child: !isReady
                              ? _defaultWidget()
                              : Container(
                                  child: StreamBuilder<List<int>>(
                                    stream: stream,
                                    builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
                                      if (snapshot.hasError)
                                        return Text('Error: ${snapshot.error}');

                                      if ((snapshot.connectionState == ConnectionState.active) &&
                                          (snapshot.data.length > 0)) {
                                        var currentValue = _dataParser(snapshot.data);
                                        String datetime = DateTime.now().toString().split('.')[0];
                                        datetime_list.add(datetime);
                                        print(datetime_list);

                                        return Center(
                                            child: Column(
                                          children: <Widget>[
                                            Container(
                                              width: 200,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Color(0xFFef7f11)),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(5))),
                                              child: Center(
                                                child: Text('${currentValue}mW/㎠',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 24)),
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            Text(
                                              'MIN : ${min_string}mW/㎠',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 18,
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            Text(
                                              'MAX : ${max_string}mW/㎠',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 18,
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            Text(
                                              'AVG : ${avg_string}mW/㎠',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ));
                                      } else {
                                        return _defaultWidget();
                                      }
                                    },
                                  ),
                                )),
                    ],
                  ),

                //_imageFile != null ? Image.file(_imageFile) : Container(),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _isbuttonStart
                        ? RaisedButton(
                            child: Text(
                              'START',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                                side: BorderSide(
                                    color: Color(0x335f3206), width: 2)),
                            onPressed: () {
                              connectToDevice();
                              connectionFlag = true;
                              setState(() {
                                _isbuttonStart = false;
                              });
                            },
                            color: Color(0xFFef7f11),
                          )
                        : RaisedButton(
                            child: Text(
                              'STOP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                                side: BorderSide(
                                    color: Color(0x335f3206), width: 2)),
                            onPressed: () {
                              disconnectFromDevice();
                              connectionFlag = false;
                              setState(() {
                                _isbuttonStart = true;
                              });
                            },
                            color: Color(0xFFef7f11),
                          ),
                    RaisedButton(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          side: BorderSide(color: Color(0x335f3206), width: 2)),
                      onPressed: () async {
                        String ans = await takeScreenShot();
                        Fluttertoast.showToast(
                          msg: '$ans에 저장되었습니다.',
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      },
                      color: Color(0xFFef7f11),
                    ),
                    RaisedButton(
                      child: Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          side: BorderSide(color: Color(0x335f3206), width: 2)),
                      onPressed: () async{
                        String ans = await getCsv();
                        Fluttertoast.showToast(
                          msg: '$ans에 저장되었습니다.',
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      },
                      color: Color(0xFFef7f11),
                    )
                  ],
                ),

              ],
            ),
          ),
        )));
  }

  Future<String> getCsv() async {

    for (int i = 0; i < datetime_list.length; i++) {
      List<dynamic> row = List();
      row.add(datetime_list[i]);
      row.add(powerVal_list[i]);
      print('powerval : ${powerVal_list[i]}');
      row.add(max_list[i]);
      row.add(min_list[i]);
      row.add(avg_list[i]);rows.add(row);
    }

    String temp = DateTime.now().toString().split('.')[0];
    List<String> date = temp.split(' ')[0].split('-');
    List<String> time = temp.split(' ')[1].split(':');
    String datetime = '${date[0]}${date[1]}${date[2]}${time[0]}${time[1]}${time[2]}';
    print(datetime);
    File f = new File('/storage/emulated/0/Download/UV_Intensity$datetime.csv');

    String csv = const ListToCsvConverter().convert(rows);
    f.writeAsString(csv);
    return ('/storage/emulated/0/Download');
  }

  Future<String> takeScreenShot() async {
    RenderRepaintBoundary boundary = previewContainer.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();

    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);

    String temp = DateTime.now().toString().split('.')[0];
    List<String> date = temp.split(' ')[0].split('-');
    List<String> time = temp.split(' ')[1].split(':');
    String datetime = '${date[0]}${date[1]}${date[2]}${time[0]}${time[1]}${time[2]}';

    File imgFile = new File('/storage/emulated/0/Pictures/UV_Intensity$datetime.png');
    imgFile.writeAsBytes(pngBytes);

    return ('/storage/emulated/0/Pictures');
  }
}

class _defaultWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: <Widget>[
        Container(
          width: 200,
          height: 80,
          decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFef7f11)),
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: Center(),
        ),
        SizedBox(height: 20),
        Text(
          'MIN : 0mW/㎠',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'MAX : 0mW/㎠',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'AVG : 0mW/㎠',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
          ),
        ),
      ],
    ));
  }
}
