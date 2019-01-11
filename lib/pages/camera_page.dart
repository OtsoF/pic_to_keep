import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pic_to_keep/record.dart';

class CameraPage extends StatefulWidget {
  final String _id;

  CameraPage(this._id);

  @override
  _CameraPageState createState() {
    return _CameraPageState();
  }
}

class _CameraPageState extends State<CameraPage> {
  final TextRecognizer _textRecognizer =
      FirebaseVision.instance.textRecognizer();
  bool _first = true;
  List<String> _foundText = [];

  @override
  Widget build(BuildContext context) {
    if (_first) {
      _getImage();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Add From Image'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: _foundText.isNotEmpty
                ? ListView(
                    padding: EdgeInsets.only(top: 32),
                    children: _foundText
                        .map((String row) => _buildListItem(row))
                        .toList(),
                  )
                : Center(child: Text('No text detected')),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: RaisedButton(
                    onPressed: _foundText.isEmpty ? null : _addTextToList,
                    child: Text('Add To List'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: RaisedButton(
                    onPressed: _getImage,
                    child: Text('New Image'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Future<void> _getImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.camera);
    _foundText = await _findText(image);
    setState(() {
      _first = false;
    });
  }

  Future<List<String>> _findText(File image) async {
    List<String> found = [];
    VisionText vText =
        await _textRecognizer.processImage(FirebaseVisionImage.fromFile(image));
    for (TextBlock block in vText.blocks) {
      for (TextLine line in block.lines) {
        found.add(line.text);
      }
    }
    return found;
  }

  Future<void> _addTextToList() async {
    QuerySnapshot qs = await Firestore.instance
        .collection('list')
        .document(widget._id)
        .collection('items')
        .getDocuments();

    for (DocumentSnapshot document in qs.documents) {
      Record r = Record.fromSnapshot(document);
      print("processing: ${r.value}");
      int idx = _foundText.indexOf(r.value);
      if (idx != -1) {
        //found, uncheck if checked and remove from _foundText
        if (r.checked) r.reference.updateData({'checked': false});
        print("removing: ${_foundText[idx]}");
        _foundText.removeAt(idx);
      }
    }

    //finally add new items
    for (String item in _foundText) {
      print("adding: $item");
      Firestore.instance
          .collection('list')
          .document(widget._id)
          .collection('items')
          .document()
          .setData({'value': item, 'checked': false});
    }
    _foundText = [];
    Navigator.pop(context);
  }
}
