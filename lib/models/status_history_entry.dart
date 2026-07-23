import 'package:equatable/equatable.dart';
import 'paper.dart';

class StatusHistoryEntry extends Equatable {
  final String id;
  final PaperStatus oldStatus;
  final PaperStatus newStatus;
  final String changedByUserId;
  final String changedByUserName;
  final DateTime timestamp;

  final String note;

  const StatusHistoryEntry({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    required this.changedByUserId,
    this.changedByUserName = '',
    this.note = '',
    required this.timestamp,
  });

  StatusHistoryEntry copyWith({
    String? id,
    PaperStatus? oldStatus,
    PaperStatus? newStatus,
    String? changedByUserId,
    String? changedByUserName,
    String? note,
    DateTime? timestamp,
  }) {
    return StatusHistoryEntry(
      id: id ?? this.id,
      oldStatus: oldStatus ?? this.oldStatus,
      newStatus: newStatus ?? this.newStatus,
      changedByUserId: changedByUserId ?? this.changedByUserId,
      changedByUserName: changedByUserName ?? this.changedByUserName,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'oldStatus': oldStatus.name,
      'newStatus': newStatus.name,
      'changedByUserId': changedByUserId,
      'changedByUserName': changedByUserName,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StatusHistoryEntry.fromMap(String id, Map<String, dynamic> map) {
    return StatusHistoryEntry(
      id: id,
      oldStatus: PaperStatus.values.firstWhere(
        (e) => e.name == map['oldStatus'],
        orElse: () => PaperStatus.idea,
      ),
      newStatus: PaperStatus.values.firstWhere(
        (e) => e.name == map['newStatus'],
        orElse: () => PaperStatus.idea,
      ),
      changedByUserId: map['changedByUserId'] ?? '',
      changedByUserName: map['changedByUserName'] ?? '',
      note: map['note'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, oldStatus, newStatus, changedByUserId, changedByUserName, note, timestamp];
}
