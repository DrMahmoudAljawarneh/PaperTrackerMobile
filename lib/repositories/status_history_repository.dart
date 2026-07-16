import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/status_history_entry.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';

class StatusHistoryRepository {
  final FirebaseDatabase _db;

  StatusHistoryRepository({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  DatabaseReference _ref(String paperId) =>
      _db.ref('status_history/$paperId');

  Future<void> addEntry(String paperId, StatusHistoryEntry entry) async {
    final newRef = _ref(paperId).push();
    await newRef.set(entry.toMap());
  }

  Stream<List<StatusHistoryEntry>> getHistory(String paperId) {
    return _ref(paperId).orderByChild('timestamp').onValue.map((event) {
      if (!event.snapshot.exists) return <StatusHistoryEntry>[];
      final data = safeCastMap(event.snapshot.value);
      final entries = data.entries
          .map((e) =>
              StatusHistoryEntry.fromMap(e.key, safeCastMap(e.value)))
          .toList();
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return entries;
    });
  }
}
