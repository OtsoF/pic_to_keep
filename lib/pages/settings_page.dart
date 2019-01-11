import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  final String _currentListID;
  final List<String> _listIDs;
  final Function(String, List<String>) _setPersisted;

  SettingsPage(this._currentListID, this._listIDs, this._setPersisted);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _addExternalController = TextEditingController();
  final TextEditingController _createController = TextEditingController();

  @override
  void dispose() {
    _addExternalController.dispose();
    _createController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 32.0),
          child: Text(
            'My Lists',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
        _buildMyListsList(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Divider(),
        ),
        _buildCreateNewList(context),
        _buildAddExternalList(context),
      ],
    );
  }

  Widget _buildMyListsList() {
    if (widget._listIDs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 16.0),
        child: Text('No lists yet, add or create one below.'),
      );
    }

    List<Widget> completeList = [];
    for (String id in widget._listIDs) {
      completeList
          .add(MyListsRow(id, widget._currentListID, widget._setPersisted));
    }
    return Column(
      children: completeList,
    );
  }

  Widget _buildCreateNewList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Create New List',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: TextField(
              controller: _createController,
              onSubmitted: (s) => _createNewList(s, context),
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: 'List name'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewList(String name, BuildContext context) async {
    _createController.clear();
    if (name.length > 0 && name.length < 50) {
      DocumentReference docRef = Firestore.instance
          .collection('list')
          .document()
            ..setData({'name': name})
            ..collection('items')
                .document()
                .setData({'checked': false, 'value': ''});
      if (widget._listIDs.isEmpty) {
        widget._setPersisted(docRef.documentID, [docRef.documentID]);
      } else {
        widget._setPersisted(
            null, [docRef.documentID]..addAll(widget._listIDs));
      }
    } else {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid! Name must be between 1 and 50 characters'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAddExternalList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Connect To List',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: TextField(
              controller: _addExternalController,
              onSubmitted: (s) => _addExternalList(s, context),
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: 'List ID'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addExternalList(String id, BuildContext context) async {
    _addExternalController.clear();
    if (widget._listIDs.contains(id)) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text('Aleardy connected to: $id'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (id.length == 20) {
      Firestore.instance
          .collection('list')
          .document(id)
          .snapshots()
          .listen((snap) {
        if (snap.data == null || snap.data['name'].toString().isEmpty) {
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid ID'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          if (widget._listIDs.isEmpty) {
            widget._setPersisted(id, [id]);
          } else {
            widget._setPersisted(null, [id]..addAll(widget._listIDs));
          }
        }
      });
    } else {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid ID length (${id.length}), should be 20.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class MyListsRow extends StatefulWidget {
  final String _id;
  final String _currentID;
  final Function(String, List<String>) _setPersisted;

  MyListsRow(this._id, this._currentID, this._setPersisted);

  @override
  _MyListsRowState createState() => _MyListsRowState();
}

class _MyListsRowState extends State<MyListsRow> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance
          .collection('list')
          .document(widget._id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return RadioListTile<String>(
          groupValue: widget._currentID,
          onChanged: _setCurrentList,
          value: widget._id,
          title: Text(snapshot.data.data['name']),
          subtitle: Text(widget._id),
          secondary: IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget._id));
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied ' + widget._id),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _setCurrentList(String newCurrent) async {
    widget._setPersisted(newCurrent, null);
  }
}
