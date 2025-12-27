import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> init() async {
    // keep if you need it, otherwise can remove
  }

  Future<void> add(Event e) async {
    await _db.collection('events').doc(e.id).set(e.toJson());
  }

  Stream<List<Event>> watchAll() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromJson(d.data())).toList());
  }

  Future<void> remove(String id) async {
    await _db.collection('events').doc(id).delete();
  }
}
