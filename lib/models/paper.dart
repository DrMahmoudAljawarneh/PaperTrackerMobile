import 'package:equatable/equatable.dart';

enum PaperStatus {
  idea,
  drafting,
  writing,
  internalReview,
  submitted,
  underReview,
  revision,
  accepted,
  published,
  rejected;

  String get label {
    switch (this) {
      case PaperStatus.idea:
        return 'Idea';
      case PaperStatus.drafting:
        return 'Drafting';
      case PaperStatus.writing:
        return 'Writing';
      case PaperStatus.internalReview:
        return 'Internal Review';
      case PaperStatus.submitted:
        return 'Submitted';
      case PaperStatus.underReview:
        return 'Under Review';
      case PaperStatus.revision:
        return 'Revision';
      case PaperStatus.accepted:
        return 'Accepted';
      case PaperStatus.published:
        return 'Published';
      case PaperStatus.rejected:
        return 'Rejected';
    }
  }

  String get emoji {
    switch (this) {
      case PaperStatus.idea:
        return '💡';
      case PaperStatus.drafting:
        return '📝';
      case PaperStatus.writing:
        return '✍️';
      case PaperStatus.internalReview:
        return '🔍';
      case PaperStatus.submitted:
        return '📤';
      case PaperStatus.underReview:
        return '🔄';
      case PaperStatus.revision:
        return '📝';
      case PaperStatus.accepted:
        return '✅';
      case PaperStatus.published:
        return '📰';
      case PaperStatus.rejected:
        return '❌';
    }
  }
}

enum PaperPriority {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case PaperPriority.high:
        return 'High';
      case PaperPriority.medium:
        return 'Medium';
      case PaperPriority.low:
        return 'Low';
    }
  }
}

class Paper extends Equatable {
  final String id;
  final String title;
  final String abstract_;
  final PaperStatus status;
  final PaperPriority priority;
  final List<String> authorIds;
  final List<String> authors;
  final String leadAuthorId;
  final String targetVenue;
  final DateTime? deadline;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Paper({
    required this.id,
    required this.title,
    this.abstract_ = '',
    this.status = PaperStatus.idea,
    this.priority = PaperPriority.medium,
    this.authorIds = const [],
    this.authors = const [],
    required this.leadAuthorId,
    this.targetVenue = '',
    this.deadline,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Paper copyWith({
    String? id,
    String? title,
    String? abstract_,
    PaperStatus? status,
    PaperPriority? priority,
    List<String>? authorIds,
    List<String>? authors,
    String? leadAuthorId,
    String? targetVenue,
    DateTime? deadline,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Paper(
      id: id ?? this.id,
      title: title ?? this.title,
      abstract_: abstract_ ?? this.abstract_,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      authorIds: authorIds ?? this.authorIds,
      authors: authors ?? this.authors,
      leadAuthorId: leadAuthorId ?? this.leadAuthorId,
      targetVenue: targetVenue ?? this.targetVenue,
      deadline: deadline ?? this.deadline,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'abstract': abstract_,
      'status': status.name,
      'priority': priority.name,
      'authorIds': authorIds,
      'authors': authors,
      'leadAuthorId': leadAuthorId,
      'targetVenue': targetVenue,
      'deadline': deadline?.toIso8601String(),
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Paper.fromMap(String id, Map<String, dynamic> map) {
    return Paper(
      id: id,
      title: map['title'] ?? '',
      abstract_: map['abstract'] ?? '',
      status: PaperStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaperStatus.idea,
      ),
      priority: PaperPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => PaperPriority.medium,
      ),
      authorIds: List<String>.from(map['authorIds'] ?? []),
      authors: List<String>.from(map['authors'] ?? []),
      leadAuthorId: map['leadAuthorId'] ?? '',
      targetVenue: map['targetVenue'] ?? '',
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        abstract_,
        status,
        priority,
        authorIds,
        authors,
        leadAuthorId,
        targetVenue,
        deadline,
        tags,
        createdAt,
        updatedAt,
      ];
}
