import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:convert_hex/convert_hex.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class uvcSafe extends StatefulWidget {
  final BluetoothDevice device;

  const uvcSafe({Key key, this.device}) : super(key: key);

  @override
  _uvcSafeState createState() => _uvcSafeState();
}

class _uvcSafeState extends State<uvcSafe> {
  final String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String CHARACTERISTIC_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  bool isReady, connectionFlag = false, _isbuttonStart = true;
  Stream<List<int>> stream;
  List<String> datetime_list = ['Date/Time'];
  List<List<dynamic>> rows = List<List<dynamic>>();
  List<String> irradiation_list = [' Irradiation(mW/cm²)'];
  List<String> bio_irradiation_list = [' Biological effective irradiation(mW/cm²)'];

  static GlobalKey previewContainer = new GlobalKey();

  int wavelength = 254;
  final TextEditingController _textController = TextEditingController();

  final List<double> bio_effective_irradiation = [
  0.0120, 0.0126, 0.0132, 0.0138, 0.0144, 0.0151, 0.0158, 0.0166, 0.0173, 0.0181,  // from lambda = 180 to 189
  0.0190, 0.0199, 0.0208, 0.0218, 0.0228, 0.0239, 0.0250, 0.0262, 0.0274, 0.0287,  // 190 to 199
  0.0300, 0.0334, 0.0371, 0.0412, 0.0459, 0.0510, 0.0551, 0.0595, 0.0643, 0.0694,  // 200 to 209
  0.0750, 0.0786, 0.0824, 0.0864, 0.0906, 0.0950, 0.0995, 0.1043, 0.1093, 0.1145,  // 210 to 219
  0.1200, 0.1257, 0.1316, 0.1378, 0.1444, 0.1500, 0.1583, 0.1658, 0.1737, 0.1819,  // 220 to 229
  0.1900, 0.1995, 0.2089, 0.2188, 0.2292, 0.2400, 0.2510, 0.2624, 0.2744, 0.2869,  // 230 to 239
  0.3000, 0.3111, 0.3227, 0.3347, 0.3471, 0.3600, 0.3730, 0.3865, 0.4005, 0.4150,  // 240 to 249
  0.4300, 0.4465, 0.4637, 0.4815, 0.5000, 0.5200, 0.5437, 0.5685, 0.5945, 0.6216,  // 250 to 259
  0.6500, 0.6792, 0.7098, 0.7417, 0.7751, 0.8100, 0.8449, 0.8812, 0.9192, 0.9587,  // 260 to 269
  1.0000, 0.9919, 0.9838, 0.9758, 0.9679, 0.9600, 0.9434, 0.9272, 0.9112, 0.8954,  // 270 to 279
  0.8800, 0.8568, 0.8342, 0.8122, 0.7908, 0.7700, 0.7420, 0.7151, 0.6891, 0.6641,  // 280 to 289
  0.6400, 0.6186, 0.5980, 0.5780, 0.5587, 0.5400, 0.4984, 0.4600, 0.3989, 0.3459,  // 290 to 299
  0.3000, 0.2210, 0.1629, 0.1200, 0.0849, 0.0600, 0.0454, 0.0344, 0.0260, 0.0197,  // 300 to 309
  0.0150, 0.0111, 0.0081, 0.0060, 0.0042, 0.0030, 0.0024, 0.0020, 0.0016, 0.0012,  // 310 to 319
  0.0010, 0.000819, 0.000670, 0.000540, 0.000520, 0.000500, 0.000479, 0.000459, 0.000440, 0.000425,  // 320 to 329
  0.000410, 0.000396, 0.000383, 0.000370, 0.000355, 0.000340, 0.000327, 0.000315, 0.000303, 0.000291, // 330 to 339
  0.000280, 0.000271, 0.000263, 0.000255, 0.000248, 0.000240, 0.000231, 0.000223, 0.000215, 0.000207, // 340 to 349
  0.000200, 0.000191, 0.000183, 0.000175, 0.000167, 0.000160, 0.000153, 0.000147, 0.000141, 0.000136, // 350 to 359
  0.000130, 0.000126, 0.000122, 0.000118, 0.000114, 0.000110, 0.000106, 0.000103, 0.000099, 0.000096, // 360 to 369
  0.000093, 0.000090, 0.000086, 0.000083, 0.000080, 0.000077, 0.000074, 0.000072, 0.000069, 0.000066, // 370 to 379
  0.000064, 0.000062, 0.000059, 0.000057, 0.000055, 0.000053, 0.000051, 0.000049, 0.000047, 0.000046, // 380 to 389
  0.000044, 0.000042, 0.000041, 0.000039, 0.000037, 0.000036, 0.000035, 0.000033, 0.000032, 0.000031, // 390 to 399
  0.000030                                                                                            // lambda is 400
  ];

  final int wave_length_start = 180;
  final int wave_length_end = 400;

  double compute_BioEffective(double uvc_irradiation, int uvc_wave_length) {
    if ((uvc_wave_length < wave_length_start) ||
        (uvc_wave_length > wave_length_end)) return 0.0;
    int bei_table_index = uvc_wave_length - wave_length_start;
    return bio_effective_irradiation[bei_table_index];
  }

  static const uvc_safe_01seconds = 14; // 0.1 second
  static const uvc_safe_05seconds = 13; // 0.5 second
  static const uvc_safe_1seconds = 12; // 1 second
  static const uvc_safe_10seconds = 11;
  static const uvc_safe_30seconds = 10;
  static const uvc_safe_1minutes = 9;
  static const uvc_safe_5minutes = 8;
  static const uvc_safe_10minutes = 7;
  static const uvc_safe_15minutes = 6;
  static const uvc_safe_30minutes = 5;
  static const uvc_safe_1hours = 4;
  static const uvc_safe_2hours = 3;
  static const uvc_safe_4hours = 2;
  static const uvc_safe_8hours = 1;
  static const uvc_safe_24hours = 0;

  final List<double> exposure_and_irradiation = [
    0, 0.0001, 0.0002, 0.0004, 0.0008, 0.0017, 0.0033, 0.005, 0.01, 0.05, 0.1, 0.3, 3, 6, 10
  ];

  int get_exposure_duration(double irradiation) {
    if(irradiation != 0){
      for (var i = uvc_safe_24hours; i <= uvc_safe_01seconds; i++) {
        if (irradiation <= exposure_and_irradiation[i+1] && irradiation > exposure_and_irradiation[i]) return (i);
      }
    }
    else
      return 0;
    //return (uvc_safe_01seconds + 1);  //에러처리
  }

  List<String> uvc_safe_image = [
    'uvc_safe_level_white_01_n.png', // 24hours
    'uvc_safe_level_white_02_n.png', // 8hours
    'uvc_safe_level_white_03_n.png', // 4hours
    'uvc_safe_level_white_04_n.png', // 2hours
    'uvc_safe_level_white_05_n.png', // 1hours
    'uvc_safe_level_white_06_n.png', // 30min
    'uvc_safe_level_white_07_n.png', // 10min
    'uvc_safe_level_white_08_n.png', // 5min
    'uvc_safe_level_white_09_n.png', // 2min
    'uvc_safe_level_white_10_n.png', // 1min
    'uvc_safe_level_white_11_n.png', // 1min
    'uvc_safe_level_white_11_n.png',
    'uvc_safe_level_white_11_n.png',
    'uvc_safe_level_white_11_n.png',
    'uvc_safe_level_white_11_n.png'
  ];

  String get_display_image_file(int duration) {
    /*uvc_safe_image.forEach(
            (k,v) => if(k == duration) return v;
            );*/
    return uvc_safe_image[duration];
  }

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
    String result = '0';
    double adc_val;
    if (a.length > 0) {
      List<String> arr = a.split(' ');
      print(arr);
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
      irradiation_list.add(result);
    }
    else
      irradiation_list.add(result);

    print('result : $result');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: RepaintBoundary(
        key: previewContainer,
        child: Scaffold(
            resizeToAvoidBottomInset : false,
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
                      Text('UVC Safe'),
                    ],
                  )),
                ],
              ),
              backgroundColor: Color(0xFFef7f11),
            ),
            body: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 10),
                  Text(
                    'Maximum Exposition Time / Day',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        Text(
                          'UVC Wavelength: ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                          ),
                        ),
                        InkWell(
                          child: Row(
                            children: [
                              Text('${wavelength}nm'),
                              Icon(Icons.keyboard_arrow_down)
                            ],
                          ),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Container(
                                      width: 200,
                                      height: 100,
                                      child: Center(
                                        child: Column(
                                          children: <Widget>[
                                            Text('UVC Wavelength: ',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold)),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            TextField(
                                              controller: _textController,
                                              keyboardType: TextInputType.number,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: <Widget>[
                                      FlatButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Cancel"),
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          setState(() {
                                            wavelength =
                                                int.parse(_textController.text);
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Confirm"),
                                      ),
                                    ],
                                  );
                                });
                          },
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    child: !isReady
                        ? _defaultWidget()
                        : StreamBuilder<List<int>>(
                            stream: stream,
                            builder: (BuildContext context,
                                AsyncSnapshot<List<int>> snapshot) {
                              if (snapshot.hasError)
                                return Text('Error: ${snapshot.error}');

                              if ((snapshot.connectionState == ConnectionState.active) && (snapshot.data.length > 0)) {
                                print(snapshot.data);
                                double currentValue = double.parse(_dataParser(snapshot.data));

                                String datetime = DateTime.now().toString().split('.')[0];
                                datetime_list.add(datetime);
                                print(datetime_list);

                                double irradiation = currentValue * compute_BioEffective(currentValue, wavelength);
                                String bio_irradiation = irradiation.toString();

                                if(bio_irradiation.length > 7)
                                  bio_irradiation = irradiation.toString().substring(7);
                                bio_irradiation_list.add(bio_irradiation);

                                int i = get_exposure_duration(irradiation);
                                String imagepath;
                                if(i != 0)
                                  imagepath = 'images/' + get_display_image_file(i);
                                else
                                  imagepath = 'images/uvc_safe_level_white_00_n.png';

                                return Column(
                                  children: <Widget>[
                                    Image(
                                      image: AssetImage(imagepath),
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Text('Biological effective')
                                      ],
                                    ),
                                    Container(
                                        child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text('Irradiation'),
                                            Text(
                                              '$currentValue mW/㎠',
                                              style: TextStyle(fontSize: 20),
                                            )
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Text('Irradiation'),
                                            Text(
                                              '$bio_irradiation mW/㎠',
                                              style: TextStyle(fontSize: 20),
                                            )
                                          ],
                                        )
                                      ],
                                    )),
                                  ],
                                );
                              } else {
                                return _defaultWidget();
                              }
                            },
                          ),
                  ),
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
                  )
                ],
              ),
            )),
      ),
    );
  }
  Future<String> getCsv() async {
    for (int i = 0; i < datetime_list.length; i++) {
      List<dynamic> row = List();
      row.add(datetime_list[i]);
      row.add(irradiation_list[i]);
      row.add(bio_irradiation_list[i]);
      rows.add(row);
    }

    String temp = DateTime.now().toString().split('.')[0];
    List<String> date = temp.split(' ')[0].split('-');
    List<String> time = temp.split(' ')[1].split(':');
    String datetime = '${date[0]}${date[1]}${date[2]}${time[0]}${time[1]}${time[2]}';
    File f = new File('/storage/emulated/0/Download/UVC_Safe$datetime.csv');

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
        Image(
          image: AssetImage('images/uvc_safe_level_white_00_n.png'),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[Text('Biological effective')],
        ),
        Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Irradiation'),
                Text(
                  '0 mW/㎠',
                  style: TextStyle(fontSize: 20),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text('Irradiation'),
                Text(
                  '0.000 mW/㎠',
                  style: TextStyle(fontSize: 20),
                )
              ],
            )
          ],
        )),
      ],
    );
  }
}
