import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:convert_hex/convert_hex.dart';
import 'package:csv/csv.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class uvIndex extends StatefulWidget {
  final BluetoothDevice device;

  const uvIndex({Key key, this.device}) : super(key: key);

  @override
  _uvIndexState createState() => _uvIndexState();
}

class _uvIndexState extends State<uvIndex> {
  final String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String CHARACTERISTIC_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  bool isReady, connectionFlag = false, _isbuttonStart = true;
  Stream<List<int>> stream;
  String UVIndex, imagesource;
  List<String> voltage_list = [' UV Voltage(Hex)'];
  List<String> index_list = [' UVINDEX'];
  List<String> datetime_list = ['Date/Time'];
  List<List<dynamic>> rows = List<List<dynamic>>();
  static GlobalKey previewContainer = new GlobalKey();
  final int green = 0xFF77AE38, yellow = 0xFFECAC1D, orange = 0xFFE3811E,
    red = 0xFFD3422A, purple = 0xFF9F5A8F;

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
    Navigator.of(context).pop(true);
  }
  _Pop() {
    Navigator.of(context).pop(true);
  }
  String _dataParser(List<int> dataFromDevice) {
    String a = utf8.decode(dataFromDevice);
    print(a);


    String result;
    int adc_val;
    if (a.length > 0) {
      List<String> arr = a.split(' ');
      if((Hex.decode(arr[1]) > 3100) && (Hex.decode(arr[2]) > 3100) && (Hex.decode(arr[3]) > 3100) && (Hex.decode(arr[4]) > 3100))
        adc_val = 0;
      else{
        voltage_list.add(arr[1]);
        adc_val = Hex.decode(arr[1]);
      }

      print('adc_val = $adc_val');
    }

    if(adc_val>=0 && adc_val<=275)
      result = '0';
    else if(adc_val <= 550)
      result = '1';
    else if(adc_val <= 825)
      result = '2';
    else if(adc_val <= 1100)
      result = '3';
    else if(adc_val <= 1375)
      result = '4';
    else if(adc_val <= 1650)
      result = '5';
    else if(adc_val <= 1925)
      result = '6';
    else if(adc_val <= 2200)
      result = '7';
    else if(adc_val <= 2475)
      result = '8';
    else if(adc_val <= 2750)
      result = '9';
    else if(adc_val <= 3025)
      result = '10';
    else if(adc_val <= 3300)
      result = '11+';
    else if(adc_val == 65530)
      result = '0';

    return result;
  }

  final List<String> index_graph = [
    'uv_index_graph_0.png', 'uv_index_graph_1.png', 'uv_index_graph_2.png', 'uv_index_graph_3.png', 'uv_index_graph_4.png',
    'uv_index_graph_5.png', 'uv_index_graph_6.png', 'uv_index_graph_7.png', 'uv_index_graph_8.png', 'uv_index_graph_9.png',
    'uv_index_graph_10.png', 'uv_index_graph_11.png'
  ];

  final List<String> phrases = [
    'Minimal sun protection required (unless near water or snow). Wear sunglasses if bright.',
    'Take precautions - wear sunscreen, sunhat, sunglasses, seek shade during peak hours of 11 am to 4 pm.',
    'Wear sun protective clothing, sunscreen, and seek shade.',
    'Seek shade - wear sun protective clothing, sun screen & sunglasses. White sand increases UV radiation exposure.',
    'Take full precautions. Unprotected skin can burn in minutes. Avoid the sun between 11 am and 4 pm, wear sunscreens'
        '& sun protective clothing.'
  ];

  int get_index(String currentValue){
    if(currentValue != '11+'){
      return int.parse(currentValue);
    }
    else{
      String str = currentValue.substring(0,2);
      return int.parse(str);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: RepaintBoundary(
        key: previewContainer,
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
                  Expanded(flex: 1, child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('UV Index'),
                    ],
                  )),
                ],
              ),
              backgroundColor: Color(0xFFef7f11),
            ),
            body: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: !isReady
                        ? _defaultWidget()
                    : StreamBuilder<List<int>>(
                      stream: stream,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<int>> snapshot) {
                        if (snapshot.hasError)
                          return Text('Error: ${snapshot.error}');

                        if ((snapshot.connectionState == ConnectionState.active) &&
                            (snapshot.data.length > 0)) {
                          var currentValue = _dataParser(snapshot.data);
                          index_list.add(currentValue);

                          String datetime = DateTime.now().toString().split('.')[0];
                          datetime_list.add(datetime);
                          print(datetime_list);

                          int graph_index = get_index(currentValue);
                          int phrase_index = 0;
                          int textcolor = green;

                          if(currentValue == '0' || currentValue == '1' || currentValue == '2'){
                            UVIndex = 'LOW';
                            imagesource = 'images/uv_index_low.png';
                            phrase_index = 0;
                            textcolor = green;
                          }
                          else if(currentValue == '3' || currentValue == '4' || currentValue == '5'){
                            UVIndex = 'MODERATE';
                            imagesource = 'images/uv_index_moderate.png';
                            phrase_index = 1;
                            textcolor = yellow;
                          }
                          else if(currentValue == '6' || currentValue == '7'){
                            UVIndex = 'HIGH';
                            imagesource = 'images/uv_index_high.png';
                            phrase_index = 2;
                            textcolor = orange;
                          }
                          else if(currentValue == '8' || currentValue == '9' || currentValue == '10'){
                            UVIndex = 'VERY HIGH';
                            imagesource = 'images/uv_index_high.png';
                            phrase_index = 3;
                            textcolor = red;
                          }
                          else if(currentValue == '11+'){
                            UVIndex = 'EXTREME';
                            imagesource = 'images/uv_index_extreme.png';
                            phrase_index = 4;
                            textcolor = purple;
                          }

                          return Column(
                            children: <Widget>[
                              Image(
                                image: AssetImage('images/' + index_graph[graph_index]),
                                gaplessPlayback: true,
                              ),
                              SizedBox(height: 20),
                              Text(
                                '$currentValue UVI',
                                style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.grey[600]
                                ),
                              ),
                              Text(
                                UVIndex,
                                style: TextStyle(
                                    fontSize: 25,
                                    color: Color(textcolor)
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 30),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      phrases[phrase_index],
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 15,
                                          color: Colors.grey[600]
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                        height: 60,
                                        //padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                            border: Border.all(color: Color(0xFFef7f11)),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                            color: Colors.grey[300]
                                        ),
                                        child: Image.asset(imagesource, fit: BoxFit.fitWidth)
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return _defaultWidget();
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 40),
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
                            msg: '/storage/emulated/0/Pictures에 저장되었습니다.',
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
                  )
                ],
              ),
            )
        ),
      ),
    );
  }
  Future<String> getCsv() async {
    for (int i = 0; i <datetime_list.length;i++) {
      List<dynamic> row = List();
      row.add(datetime_list[i]);
      row.add(voltage_list[i]);
      row.add(index_list[i]);

      rows.add(row);
    }

    String temp = DateTime.now().toString().split('.')[0];
    List<String> date = temp.split(' ')[0].split('-');
    List<String> time = temp.split(' ')[1].split(':');
    String datetime = '${date[0]}${date[1]}${date[2]}${time[0]}${time[1]}${time[2]}';
    File f = new File('/storage/emulated/0/Download/UV_Index$datetime.csv');

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
    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            Image(
              image: AssetImage('images/uv_index_graph.png'),
            ),
            Positioned(
              left: 90,
              bottom: 0.0,
              child: RotationTransition(
                turns: AlwaysStoppedAnimation(-0.5 / 360),
                child: Image(
                  image: AssetImage('images/uv_index_pin.png'),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          '0 UVI',
          style: TextStyle(
              fontSize: 25,
              color: Colors.grey[600]
          ),
        ),
        Text(
          'LOW',
          style: TextStyle(
              fontSize: 25,
              color: Color(0xFF77AE38)
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: <Widget>[
              Text(
                'Minimal sun protection required (unless near water or snow). '
                    'Wear sunglasses if bright.',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    color: Colors.grey[600]
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Container(
                  height: 60,
                  //padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFef7f11)),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.grey[300]
                  ),
                  child: Image.asset('images/uv_index_low.png', fit: BoxFit.fitWidth)
              ),
            ],
          ),
        ),
      ],
    );
  }
}
