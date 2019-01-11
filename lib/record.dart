import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String value;
  final bool checked;

  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['value'] != null),
        assert(map['checked'] != null),
        value = map['value'],
        checked = map['checked'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => 'Record<$value:$checked>';
}