import 'orcid_person.dart';
import 'orcid_employment.dart';
import 'orcid_education.dart';
import 'orcid_work.dart';
import 'orcid_funding.dart';

class OrcidRecord {
  final String orcidId;
  final OrcidPerson person;
  final List<OrcidEmployment> employments;
  final List<OrcidEducation> educations;
  final List<OrcidWork> works;
  final List<OrcidFunding> fundings;
  final List<String> qualifications;
  final List<String> memberships;

  const OrcidRecord({
    this.orcidId = '',
    required this.person,
    this.employments = const [],
    this.educations = const [],
    this.works = const [],
    this.fundings = const [],
    this.qualifications = const [],
    this.memberships = const [],
  });

  factory OrcidRecord.fromJson(Map<String, dynamic> json) {
    final person = OrcidPerson.fromJson(json);
    final orcidId = (json['orcid-identifier'] as Map<String, dynamic>?)?['path']?.toString() ?? '';

    final activities = json['activities-summary'] as Map<String, dynamic>? ?? {};

    final employments = _extractAffiliations(activities['employments'], 'employment-summary', OrcidEmployment.fromJson);
    final educations = _extractAffiliations(activities['educations'], 'education-summary', OrcidEducation.fromJson);
    final works = _extractGroups(activities['works'], 'work-summary', _extractWorkFromGroup);
    final fundings = _extractGroups(activities['fundings'], 'funding-summary', OrcidFunding.fromJson);
    final qualifications = _extractAffiliations(activities['qualifications'], 'qualification-summary', _extractName).whereType<String>().toList();
    final memberships = _extractAffiliations(activities['memberships'], 'membership-summary', _extractName).whereType<String>().toList();

    return OrcidRecord(
      orcidId: orcidId,
      person: person,
      employments: employments,
      educations: educations,
      works: works,
      fundings: fundings,
      qualifications: qualifications,
      memberships: memberships,
    );
  }

  static List<T> _extractAffiliations<T>(dynamic categoryNode, String summaryKey, T Function(Map<String, dynamic>) mapper) {
    if (categoryNode is! Map) return [];
    final groups = categoryNode['affiliation-group'] as List<dynamic>? ?? [];
    
    final List<T> results = [];
    for (final g in groups) {
      if (g is! Map) continue;
      final summaries = g['summaries'] as List<dynamic>? ?? [];
      for (final s in summaries) {
        if (s is Map && s[summaryKey] is Map) {
          try {
            results.add(mapper(Map<String, dynamic>.from(s[summaryKey])));
          } catch (_) {}
        }
      }
    }
    return results;
  }

  static List<T> _extractGroups<T>(dynamic categoryNode, String summaryKey, T Function(Map<String, dynamic>) mapper) {
    if (categoryNode is! Map) return [];
    final groups = categoryNode['group'] as List<dynamic>? ?? [];
    
    final List<T> results = [];
    for (final g in groups) {
      if (g is! Map) continue;
      final summaries = g[summaryKey];
      if (summaries is List && summaries.isNotEmpty) {
        final first = summaries.first;
        if (first is Map) {
          try {
            results.add(mapper(Map<String, dynamic>.from(first)));
          } catch (_) {}
        }
      }
    }
    return results;
  }

  static String? _extractName(Map<String, dynamic> summary) {
    final org = summary['organization'] as Map<String, dynamic>?;
    final role = summary['role-title']?.toString() ?? '';
    final orgName = org?['name']?.toString() ?? '';
    final result = '$role at $orgName'.trim();
    return result.isEmpty ? null : result;
  }

  static OrcidWork _extractWorkFromGroup(Map<String, dynamic> summary) {
    return OrcidWork.fromJson(summary);
  }

  int get publicationCount => works.length;
  int get employmentCount => employments.length;
  int get educationCount => educations.length;
  int get fundingCount => fundings.length;
  int get qualificationCount => qualifications.length;
  int get membershipCount => memberships.length;
}
