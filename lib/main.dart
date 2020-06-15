import 'dart:async';
import 'package:flutter/material.dart';
import 'FlutterBlueApp.dart';

void main() {
  runApp(
      MaterialApp(
    home: SplashScreen()
  ));
}

class SplashScreen extends StatefulWidget {
  @override
  Splash createState() => Splash();
}

class Splash extends State<SplashScreen>  {

  @override
  void initState() {
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    Timer(
        Duration(seconds: 1), () =>
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => FlutterBlueApp())));

    var assetsImage = new AssetImage(
        'images/intro.png'); //<- Creates an object that fetches an image.
    var image = new Image(
        image: assetsImage,
        ); //<- Creates a widget that displays an image.

    return Scaffold(
        /* appBar: AppBar(
          title: Text("MyApp"),
          backgroundColor:
              Colors.blue, //<- background color to combine with the picture :-)
        ),*/
        body: Container(
          decoration: new BoxDecoration(color: Colors.white),
          child: new Center(
            child: image,
          ),
        ), //<- place where the image appears

    );
  }
}