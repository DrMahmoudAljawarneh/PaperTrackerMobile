import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String paperId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.paperId,
    required this.authorId,
    this.authorName = '',
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paperId': paperId,
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Comment.fromMap(String id, Map<String, dynamic> map) {
    return Comment(
      id: id,
      paperId: map['paperId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, paperId, authorId, authorName, text, createdAt];
}
