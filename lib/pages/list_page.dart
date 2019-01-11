import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pic_to_keep/record.dart';

class ListPage extends StatefulWidget {
  final String _listId;

  ListPage(this._listId);

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final TextEditingController _textController = TextEditingController();
  String _title = 'No Name';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _getTitle();
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('list')
          .document(widget._listId)
          .collection('items')
          .orderBy('value')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    List<Widget> checked = [];
    List<Widget> completeList = [];

    // add title
    completeList.add(Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 32.0),
      child: Text(
        _title,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    // add unchecked, checked to own list
    for (DocumentSnapshot data in snapshot) {
      final record = Record.fromSnapshot(data);
      record.checked
          ? checked.add(ListRow(record, key: ValueKey(record)))
          : completeList.add(ListRow(record, key: ValueKey(record)));
    }

    // add new list item field and divider
    completeList.add(_addNewListItemField(context));
    completeList.add(Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Divider(),
    ));

    //add checked
    completeList.addAll(checked);

    return ListView(
      padding: EdgeInsets.only(top: 16.0),
      children: completeList,
    );
  }

  Widget _addNewListItemField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: Row(
        children: <Widget>[
          IconButton(
              icon: Icon(
                Icons.add,
                color: Colors.grey,
              ),
              onPressed: () => _addListItem(_textController.text)),
          new Flexible(
            child: TextField(
              style: DefaultTextStyle.of(context).style,
              controller: _textController,
              onSubmitted: _addListItem,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'List Item',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addListItem(String item) {
    if (item.length != 0) {
      _textController.clear();
      Firestore.instance
          .collection('list')
          .document(widget._listId)
          .collection('items')
          .document()
          .setData({'value': item, 'checked': false});
    }
  }

  Future<void> _getTitle() async {
    Firestore.instance
        .collection('list')
        .document(widget._listId)
        .snapshots()
        .listen((snap) {
      if (_title != snap.data['name'])
        setState(() {
          _title = snap.data['name'];
        });
    });
  }
}

class ListRow extends StatefulWidget {
  final Record _record;

  ListRow(this._record, {@required Key key}) : super(key: key);

  @override
  _ListRowState createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  TextEditingController _controller;
  FocusNode _fNode;
  bool _inFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget._record.value);
    _fNode = FocusNode()
      ..addListener(() {
        if (this.mounted) {
          if (_fNode.hasFocus) {
            setState(() {
              _inFocus = true;
            });
          } else if (!_fNode.hasFocus) {
            setState(() {
              _inFocus = false;
              _updateListItem();
            });
          }
        }
      });
  }

  @override
  dispose() {
    _controller.dispose();
    _fNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          IconButton(
            icon: widget._record.checked
                ? Icon(
                    Icons.check_box,
                    color: Colors.grey,
                  )
                : Icon(Icons.check_box_outline_blank),
            onPressed: _changeChecked,
          ),
          Expanded(
            child: TextField(
              focusNode: _fNode,
              controller: _controller,
              decoration: InputDecoration(border: InputBorder.none),
              style: widget._record.checked
                  ? TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    )
                  : null,
            ),
          ),
          Container(
            child: _inFocus
                ? IconButton(
                    icon: Icon(Icons.close),
                    onPressed: _deleteListItem,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _updateListItem() {
    if (widget._record.value != _controller.text) {
      widget._record.reference.updateData({'value': _controller.text});
    }
  }

  void _changeChecked() {
    if (widget._record.value != _controller.text) {
      widget._record.reference.updateData(
          {'checked': !widget._record.checked, 'value': _controller.text});
    } else {
      widget._record.reference.updateData({'checked': !widget._record.checked});
    }
  }

  void _deleteListItem() {
    widget._record.reference.delete();
  }
}
