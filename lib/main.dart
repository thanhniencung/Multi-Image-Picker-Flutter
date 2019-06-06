import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:dio/dio.dart';
import 'package:flutter_upload_images/upload_image.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 100,
                height: 100,
                child: RaisedButton(
                  onPressed: () {
                    getImage();
                  },
                  color: Colors.white,
                  shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(7.0)),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.deepOrange,
                        size: 30.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 40,),
          SizedBox(
            width: 500,
            height: 500,
            child: _isUploading == true ? FutureBuilder(
              future: uploadImage(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return new Text('loading...');
                  default:
                    if (snapshot.hasError)
                      return new Text('${snapshot.error}');
                    else
                      return createListView(context, snapshot);
                }
              },
            ) : Text(""),
          ),

        ],
      )
    );
  }

  Future getImage() async {
    files.clear();

    List<Asset> resultList = List<Asset>();
     resultList = await MultiImagePicker.pickImages(
      maxImages :  2,
      enableCamera: false,
    );

    for (var asset in resultList) {

      int MAX_WIDTH = 500; //keep ratio
      int height = ((500 * asset.originalHeight) / asset.originalWidth).round();

      ByteData byteData = await asset.requestThumbnail(MAX_WIDTH, height, quality: 80);

      if (byteData != null) {
        List<int> imageData = byteData.buffer.asUint8List();
        UploadFileInfo u = UploadFileInfo.fromBytes(imageData, asset.name);
        files.add(u);
      }

    }

    setState(() {
      _isUploading = true;
    });
  }

  List<UploadFileInfo> files = new List<UploadFileInfo>();
  Future<List<String>> uploadImage() async {

     FormData formData = new FormData.from({
        "files": files
     });

      Dio dio = new Dio();
      var response = await dio.post(
        "http://localhost:3004/upload",
        data: formData
      );

     UploadImage image = UploadImage.fromJson(response.data);
     return image.images;
  }

  Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Text("error createListView");
    }

    if (!snapshot.hasData) {
        return Text("");
    }

    List<String> values = snapshot.data;

    return new ListView.builder(
      shrinkWrap: true,
      itemCount: values.length,
      itemBuilder: (BuildContext context, int index) {
        return new Column(
          children: <Widget>[
            Image.network(
                values[index],
                width: 300,
                height: 100,
            ),
            SizedBox(height: 40,),
          ],

        );
      },
    );
  }
}
