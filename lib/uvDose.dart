import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:convert_hex/convert_hex.dart';
import 'package:csv/csv.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:ui' as ui;

class uvDose extends StatefulWidget {
  final String band;
  final BluetoothDevice device;
  final PageController controller;

  const uvDose({Key key, this.band, this.device, this.controller}) : super(key: key);

  @override
  _uvDoseState createState() => _uvDoseState();
}

class _uvDoseState extends State<uvDose> {
  final String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String CHARACTERISTIC_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  bool isReady, connectionFlag = false, _isbuttonStart = true;
  Stream<List<int>> stream;
  List<UVDoseData> _uvDoseDatalist = [UVDoseData(null, null)];
  int start_minsec, cnt = 0;
  double sum_dose = 0, xAxis = 30;
  String time_start = '0', dose_J = 'mJ/㎠', power_W = 'mW/㎠';
  var start_time, end_time = ' ';
  static GlobalKey previewContainer = new GlobalKey();
  List<List<dynamic>> rows = List<List<dynamic>>();
  List<String> powerVal_list = [' UV Power(mW/cm²)'];
  List<String> datetime_list = ['Date/Time'];
  List<String> dose_list = [' Dose(mJ/cm²)'];
  Map<DateTime, double> data = {};

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
      _pop();
      return;
    }

    await widget.device.connect();
    discoverServices();
  }

  disconnectFromDevice() {
    if (widget.device == null) {
      _pop();
      return;
    }
    widget.device.disconnect();
  }

  discoverServices() async {
    if (widget.device == null) {
      _pop();
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

  _pop() {
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

    result = adc_val.toString();
    if (result.length > 6) {
      result = result.substring(0, 6);
      powerVal_list.add(result);
    } else {
      powerVal_list.add('0');
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
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
                    Text('UV Dose'),
                  ],
                )),
              ],
            ),
            backgroundColor: Color(0xFFef7f11),
          ),
          body: Container(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RepaintBoundary(
                      key: previewContainer,
                      child: Column(
                        children: <Widget>[
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
                          SizedBox(height: 10),
                          Container(
                            child: !isReady
                                ? _defalutWidget()
                                : StreamBuilder<List<int>>(
                              stream: stream,
                              builder: (BuildContext context,
                                  AsyncSnapshot<List<int>> snapshot) {
                                if (snapshot.hasError)
                                  return Text('Error: ${snapshot.error}');

                                if ((snapshot.connectionState == ConnectionState.active) &&
                                    (snapshot.data.length > 0)) {
                                  var currentValue = _dataParser(snapshot.data);
                                  cnt++;
                                  if(cnt >= xAxis && cnt % xAxis == 0){
                                    xAxis *= 2;
                                  }

                                  sum_dose += double.parse(currentValue);

                                  if(sum_dose > 1000 && dose_J == 'mJ/㎠'){
                                    sum_dose = sum_dose / 1000;
                                    dose_J = 'J/㎠';
                                  }
                                  if(sum_dose > 1000 && dose_J == 'J/㎠'){
                                    sum_dose = sum_dose / 1000;
                                    dose_J = 'kJ/㎠';
                                  }
                                  if(sum_dose > 1000 && dose_J == 'kJ/㎠'){
                                    sum_dose = sum_dose / 1000;
                                    dose_J = 'MJ/㎠';
                                  }

                                  if (sum_dose.toString().length > 6) {
                                    sum_dose = double.parse(sum_dose.toString().substring(0, 6));
                                    dose_list.add(sum_dose.toString());
                                  }
                                  else
                                    dose_list.add(sum_dose.toString());


                                  String datetime = DateTime.now().toString().split('.')[0];
                                  datetime_list.add(datetime);
                                  print(datetime_list);

                                  end_time = DateTime.now()
                                      .toString()
                                      .split(' ')[1]
                                      .split('.')[0];

                                  var cur_time = DateTime.now().toString().split(' ')[1].split('.')[0];
                                  int cur_min = int.parse(cur_time.split(':')[1]);
                                  int cur_sec = int.parse(cur_time.split(':')[2]);
                                  int cur_minsec;
                                  print(cur_time);

                                  if (cur_min == 00)
                                    cur_minsec = cur_sec;
                                  else
                                    cur_minsec = cur_min * 60 + cur_sec;

                                  print(cur_min);
                                  print('cur_minsec: $cur_minsec');
                                  String xAxis_val = '0';
                                  int acc_sec = 0;
                                  int acc_min = 0;
                                  bool min_flag = false;

                                  if(cur_minsec - start_minsec <= 60)
                                    xAxis_val = '${cur_minsec - start_minsec}';
                                  else {
                                    int temp = cur_minsec - start_minsec;
                                    acc_sec = temp % 60;
                                    acc_min = temp ~/ 60;
                                    xAxis_val = '${acc_min}m ${acc_sec}s';
                                    min_flag = true;
                                  }
                                  print('start_minsec: $start_minsec');
                                  print('xAxis_val : $xAxis_val');

                                  _uvDoseDatalist.add(
                                      UVDoseData(xAxis_val, double.tryParse(currentValue) ?? 0)
                                  );

                                  double currentValue2 = double.parse(currentValue);
                                  if(currentValue2 > 1000 && power_W == 'mJ/㎠'){
                                    currentValue2 = currentValue2 / 1000;
                                    power_W = 'W/㎠';
                                  }
                                  if(currentValue2 > 1000 && power_W == 'W/㎠'){
                                    currentValue2 = currentValue2 / 1000;
                                    power_W = 'kW/㎠';
                                  }
                                  if(currentValue2 > 1000 && power_W == 'kW/㎠'){
                                    currentValue2 = currentValue2 / 1000;
                                    power_W = 'MW/㎠';
                                  }

                                  return Column(
                                    children: <Widget>[
                                      Container(
                                          width: (MediaQuery.of(context).size.width).toDouble(),
                                          height: (MediaQuery.of(context).size.height ~/ 2) > 300 ? 300 : (MediaQuery.of(context).size.height ~/ 2).toDouble(),
                                          child: SfCartesianChart(
                                            //legend: Legend(isVisible: false, opacity: 0.7),
                                            //title: ChartTitle(text: ''),
                                            primaryXAxis: CategoryAxis(
                                                visibleMaximum: xAxis
                                            ),
                                            series: <AreaSeries<UVDoseData, String>>[
                                              AreaSeries<UVDoseData, String>(
                                                  dataSource: _uvDoseDatalist,
                                                  opacity: 0.7,
                                                  name: 'UV Power',
                                                  xValueMapper: (UVDoseData sales, _) => sales.second,
                                                  yValueMapper: (UVDoseData sales, _) => sales.adc_val,
                                                  color: Color(0xFFFF9C25),
                                                  borderWidth: 3,
                                                  borderColor: Color(0xFFef7f11)
                                              ),
                                            ],
                                            tooltipBehavior: TooltipBehavior(enable: true),
                                          )
                                      ),
                                      SizedBox(height: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                  width: 180,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                          color: Color(0xFFef7f11))),
                                                  child: Center(
                                                      child: Text(
                                                          'UV Power'))),
                                              Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                      child: Text('$currentValue2$power_W')))
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                  width: 180,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                          color: Color(0xFFef7f11))),
                                                  child: Center(
                                                      child: Text(
                                                          'Start ~ End Time'))),
                                              Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                      child: Text(
                                                          '$start_time~$end_time')))
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                  width: 180,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                          color: Color(0xFFef7f11))),
                                                  child: Center(
                                                      child: Text('Accumulated Time'))),
                                              Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                      child: !min_flag
                                                          ? Text('${xAxis_val}sec')
                                                          : Text(xAxis_val)
                                                  )
                                              )
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                  width: 180,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                          color: Color(0xFFef7f11))),
                                                  child: Center(
                                                      child:
                                                      Text('Dose'))),
                                              Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                      child: Text('$sum_dose$dose_J')))
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  return _defalutWidget();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
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
                            start_time = DateTime.now().toString().split(' ')[1].split('.')[0];
                            int start_min = int.parse(start_time.split(':')[1]);
                            int start_sec = int.parse(start_time.split(':')[2]);

                            if (start_min == 00)
                              start_minsec = start_sec;
                            else
                              start_minsec = start_min * 60 + start_sec;
                            print('start: $start_minsec');
                            setState(() {
                              _isbuttonStart = false;
                              _uvDoseDatalist = [UVDoseData(null, null)];
                              datetime_list = [];
                              powerVal_list = [];
                              dose_list = [];
                              end_time = '0';
                              cnt = 0;
                              xAxis = 30;
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
                              side: BorderSide(
                                  color: Color(0x335f3206), width: 2)),
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
                              side: BorderSide(
                                  color: Color(0x335f3206), width: 2)),
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
                  ]))),
    );
  }

  Future<String> takeScreenShot() async {
    RenderRepaintBoundary boundary = previewContainer.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();

    String temp = DateTime.now().toString().split('.')[0];
    List<String> date = temp.split(' ')[0].split('-');
    List<String> time = temp.split(' ')[1].split(':');
    String datetime = '${date[0]}${date[1]}${date[2]}${time[0]}${time[1]}${time[2]}';

    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();

    File imgFile = new File('/storage/emulated/0/Pictures/UV_Dose$datetime.png');
    imgFile.writeAsBytes(pngBytes);

    return ('/storage/emulated/0/Pictures');
  }

  Future<String> getCsv() async {
    for (int i = 0; i < powerVal_list.length; i++) {
      List<dynamic> row = List();
      row.add(datetime_list[i]);
      row.add(powerVal_list[i]);
      print('powerval : ${powerVal_list[i]}');
      row.add(dose_list[i]);

      rows.add(row);
    }
    String temp = DateTime.now().toString().split('.')[0];
    List<String> date = temp.split(' ')[0].split('-');
    List<String> time = temp.split(' ')[1].split(':');
    String datetime = '${date[0]}${date[1]}${date[2]}${time[0]}${time[1]}${time[2]}';

    File f = new File('/storage/emulated/0/Download/UV_Dose$datetime.csv');

    String csv = const ListToCsvConverter().convert(rows);
    f.writeAsString(csv);
    return ('/storage/emulated/0/Download');
  }
}

class UVDoseData {
  UVDoseData(this.second, this.adc_val);

  final String second;
  final double adc_val;
}

class _defalutWidget extends StatelessWidget {
  List<UVDoseData> _uvDoseDatalist = [UVDoseData(null, null)];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
            width: (MediaQuery.of(context).size.width).toDouble(),
            height: (MediaQuery.of(context).size.height ~/ 2) > 300 ? 300 : (MediaQuery.of(context).size.height ~/ 2).toDouble(),
            child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <LineSeries<UVDoseData, String>>[
                  LineSeries<UVDoseData, String>(
                      dataSource: _uvDoseDatalist,
                      xValueMapper: (UVDoseData uvDose, _) => uvDose.second,
                      yValueMapper: (UVDoseData uvDose, _) => uvDose.adc_val)
                ])),
        SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                    width: 180,
                    height: 25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFef7f11))),
                    child: Center(child: Text('UV Power'))),
                Expanded(flex: 1, child: Center(child: Text('0mW/㎠')))
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                    width: 180,
                    height: 25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFef7f11))),
                    child: Center(child: Text('Start ~ End Time'))),
                Expanded(flex: 1, child: Center(child: Text('0~0')))
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                    width: 180,
                    height: 25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFef7f11))),
                    child: Center(child: Text('Accumulated Time'))),
                Expanded(flex: 1, child: Center(child: Text('0sec')))
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                    width: 180,
                    height: 25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFef7f11))),
                    child: Center(child: Text('Dose'))),
                Expanded(flex: 1, child: Center(child: Text('0mJ/㎠')))
              ],
            ),
          ],
        ),
      ],
    );
  }
}