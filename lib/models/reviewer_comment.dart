import 'package:equatable/equatable.dart';

enum ReviewItemStatus { unaddressed, inProgress, addressed }

class ReviewerComment extends Equatable {
  final String id;
  final String paperId;
  final String reviewerName; // e.g. "Reviewer 1", "Editor"
  final String commentText;
  final String responseText;
  final String assigneeId;
  final ReviewItemStatus status;
  final DateTime createdAt;

  const ReviewerComment({
    required this.id,
    required this.paperId,
    required this.reviewerName,
    required this.commentText,
    this.responseText = '',
    this.assigneeId = '',
    this.status = ReviewItemStatus.unaddressed,
    required this.createdAt,
  });

  ReviewerComment copyWith({
    String? id,
    String? paperId,
    String? reviewerName,
    String? commentText,
    String? responseText,
    String? assigneeId,
    ReviewItemStatus? status,
    DateTime? createdAt,
  }) {
    return ReviewerComment(
      id: id ?? this.id,
      paperId: paperId ?? this.paperId,
      reviewerName: reviewerName ?? this.reviewerName,
      commentText: commentText ?? this.commentText,
      responseText: responseText ?? this.responseText,
      assigneeId: assigneeId ?? this.assigneeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paperId': paperId,
      'reviewerName': reviewerName,
      'commentText': commentText,
      'responseText': responseText,
      'assigneeId': assigneeId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewerComment.fromMap(String id, Map<String, dynamic> map) {
    return ReviewerComment(
      id: id,
      paperId: map['paperId'] ?? '',
      reviewerName: map['reviewerName'] ?? 'Reviewer 1',
      commentText: map['commentText'] ?? '',
      responseText: map['responseText'] ?? '',
      assigneeId: map['assigneeId'] ?? '',
      status: ReviewItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReviewItemStatus.unaddressed,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        paperId,
        reviewerName,
        commentText,
        responseText,
        assigneeId,
        status,
        createdAt,
      ];
}
