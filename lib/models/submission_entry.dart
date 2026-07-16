import 'package:equatable/equatable.dart';

enum SubmissionOutcome { accepted, rejected, underReview, withdrawn, other }

class SubmissionEntry extends Equatable {
  final String venueName;
  final DateTime submissionDate;
  final SubmissionOutcome outcome;
  final String? notes;

  const SubmissionEntry({
    required this.venueName,
    required this.submissionDate,
    this.outcome = SubmissionOutcome.underReview,
    this.notes,
  });

  SubmissionEntry copyWith({
    String? venueName,
    DateTime? submissionDate,
    SubmissionOutcome? outcome,
    String? notes,
  }) {
    return SubmissionEntry(
      venueName: venueName ?? this.venueName,
      submissionDate: submissionDate ?? this.submissionDate,
      outcome: outcome ?? this.outcome,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueName': venueName,
      'submissionDate': submissionDate.toIso8601String(),
      'outcome': outcome.name,
      'notes': notes,
    };
  }

  factory SubmissionEntry.fromMap(Map<String, dynamic> map) {
    return SubmissionEntry(
      venueName: map['venueName'] ?? '',
      submissionDate: map['submissionDate'] != null
          ? DateTime.parse(map['submissionDate'])
          : DateTime.now(),
      outcome: SubmissionOutcome.values.firstWhere(
        (e) => e.name == map['outcome'],
        orElse: () => SubmissionOutcome.underReview,
      ),
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [venueName, submissionDate, outcome, notes];
}
