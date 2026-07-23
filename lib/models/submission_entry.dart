import 'package:equatable/equatable.dart';

enum SubmissionOutcome { accepted, rejected, revision, underReview, withdrawn, other }

class SubmissionEntry extends Equatable {
  final String venueName;
  final DateTime submissionDate;
  final DateTime? decisionDate;
  final SubmissionOutcome outcome;
  final String reviewScores; // e.g. "8/10, 6/10, Accept"
  final String? notes;

  const SubmissionEntry({
    required this.venueName,
    required this.submissionDate,
    this.decisionDate,
    this.outcome = SubmissionOutcome.underReview,
    this.reviewScores = '',
    this.notes,
  });

  SubmissionEntry copyWith({
    String? venueName,
    DateTime? submissionDate,
    DateTime? decisionDate,
    SubmissionOutcome? outcome,
    String? reviewScores,
    String? notes,
  }) {
    return SubmissionEntry(
      venueName: venueName ?? this.venueName,
      submissionDate: submissionDate ?? this.submissionDate,
      decisionDate: decisionDate ?? this.decisionDate,
      outcome: outcome ?? this.outcome,
      reviewScores: reviewScores ?? this.reviewScores,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueName': venueName,
      'submissionDate': submissionDate.toIso8601String(),
      'decisionDate': decisionDate?.toIso8601String(),
      'outcome': outcome.name,
      'reviewScores': reviewScores,
      'notes': notes,
    };
  }

  factory SubmissionEntry.fromMap(Map<String, dynamic> map) {
    return SubmissionEntry(
      venueName: map['venueName'] ?? '',
      submissionDate: map['submissionDate'] != null
          ? DateTime.parse(map['submissionDate'])
          : DateTime.now(),
      decisionDate: map['decisionDate'] != null
          ? DateTime.parse(map['decisionDate'])
          : null,
      outcome: SubmissionOutcome.values.firstWhere(
        (e) => e.name == map['outcome'],
        orElse: () => SubmissionOutcome.underReview,
      ),
      reviewScores: map['reviewScores'] ?? '',
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [venueName, submissionDate, decisionDate, outcome, reviewScores, notes];
}
