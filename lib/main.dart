import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pic_to_keep/pages/camera_page.dart';
import 'package:pic_to_keep/pages/list_page.dart';
import 'package:pic_to_keep/pages/settings_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.lightGreen,
          disabledColor: Colors.lightGreen[200],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() {
    return new _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  String _currentListID = '';
  List<String> _listIDs = [];
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadPersistedListIDs();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pic To Keep'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.list)),
            Tab(icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _currentListID.isNotEmpty
              ? ListPage(_currentListID)
              : Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'You don\'t have any lists.',
                        style: TextStyle(fontSize: 16),
                      ),
                      RaisedButton(
                        onPressed: () => _tabController.animateTo(1,
                            duration: Duration(seconds: 2)),
                        child: Text('Add first'),
                      ),
                    ],
                  ),
                ),
          SettingsPage(_currentListID, _listIDs, _setPersistedListIDs),
        ],
      ),
      floatingActionButton: FAB(_currentListID),
    );
  }

  Future<void> _loadPersistedListIDs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentListID = (prefs.getString('currentID') ?? '');
      _listIDs = (prefs.getStringList('IDs') ?? []);
    });
  }

  Future<void> _setPersistedListIDs(String newCurrent, List<String> all) async {
    setState(() {
      if (newCurrent != null) _currentListID = newCurrent;
      if (all != null) _listIDs = all;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (newCurrent != null) prefs.setString('currentID', newCurrent);
    if (all != null) prefs.setStringList('IDs', all);
  }
}

class FAB extends StatelessWidget {
  final _id;

  FAB(this._id);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (_id.isEmpty) {
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Text('You must create a list first'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraPage(_id),
            ),
          );
        }
      },
      child: Icon(Icons.add_a_photo),
    );
  }
}

