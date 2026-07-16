import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OrcidProfile {
  final String orcidId;
  final String displayName;
  final String? bio;
  final String? institution;

  const OrcidProfile({
    required this.orcidId,
    required this.displayName,
    this.bio,
    this.institution,
  });
}

enum OrcidError { invalidFormat, notFound, network }

class OrcidResult {
  final OrcidProfile? profile;
  final OrcidError? error;
  final String? message;

  const OrcidResult({this.profile, this.error, this.message});

  bool get isSuccess => profile != null;
}

class OrcidService {
  static const _apiBase = 'https://pub.orcid.org/v3.0';

  static bool isValidId(String id) {
    final cleaned = _extractId(id);
    return RegExp(r'^\d{4}-\d{4}-\d{4}-\d{3}[0-9X]$').hasMatch(cleaned);
  }

  static String normalizeId(String id) => _extractId(id);

  static String _extractId(String input) {
    final trimmed = input.trim();
    // Handle full URL: https://orcid.org/0000-0002-1825-0097
    final urlMatch =
        RegExp(r'orcid\.org/(\d{4}-\d{4}-\d{4}-\d{3}[0-9X])')
            .firstMatch(trimmed);
    if (urlMatch != null) return urlMatch.group(1)!;
    return trimmed;
  }

  static Future<OrcidResult> fetchProfile(String rawId) async {
    final orcidId = _extractId(rawId);

    if (!RegExp(r'^\d{4}-\d{4}-\d{4}-\d{3}[0-9X]$').hasMatch(orcidId)) {
      return const OrcidResult(
        error: OrcidError.invalidFormat,
        message: 'ORCID iD must be in the format 0000-0002-1825-0097',
      );
    }

    try {
      final url = Uri.parse('$_apiBase/$orcidId/record');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'PaperTracker/1.0',
        },
      );

      if (response.statusCode == 404) {
        return const OrcidResult(
          error: OrcidError.notFound,
          message: 'No ORCID profile found for this iD',
        );
      }

      if (response.statusCode == 403 || response.statusCode == 429) {
        return OrcidResult(
          error: OrcidError.network,
          message:
              'ORCID API rate limit reached (HTTP ${response.statusCode}). Try again later.',
        );
      }

      if (response.statusCode != 200) {
        return OrcidResult(
          error: OrcidError.network,
          message: 'ORCID API returned HTTP ${response.statusCode}',
        );
      }

      final profile = _parseRecord(response.body, orcidId);
      if (profile != null) return OrcidResult(profile: profile);

      return const OrcidResult(
        error: OrcidError.notFound,
        message: 'Could not parse ORCID profile. The record may be private.',
      );
    } catch (e) {
      debugPrint('ORCID fetch error: $e');
      return OrcidResult(
        error: OrcidError.network,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  static OrcidProfile? _parseRecord(String body, String orcidId) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;

      // Try /record response structure
      final person = json['person'] as Map<String, dynamic>?;
      if (person != null) {
        final name = person['name'] as Map<String, dynamic>?;
        if (name != null) {
          final given =
              _readNestedValue(name, 'given-names', 'value') ?? '';
          final family =
              _readNestedValue(name, 'family-name', 'value') ?? '';
          final bio = _readNestedValue(person, 'biography', 'value');
          return OrcidProfile(
            orcidId: orcidId,
            displayName: '$given $family'.trim(),
            bio: bio,
          );
        }
      }

      // Try direct name fields (some endpoints)
      final name = json['name'] as Map<String, dynamic>?;
      if (name != null) {
        final given = name['given-names']?.toString() ?? '';
        final family = name['family-name']?.toString() ?? '';
        final displayName = '$given $family'.trim();
        if (displayName.isNotEmpty) {
          return OrcidProfile(orcidId: orcidId, displayName: displayName);
        }
      }

      // Fallback: try top-level given-names / family-name
      final given = json['given-names']?.toString() ?? '';
      final family = json['family-name']?.toString() ?? '';
      final displayName = '$given $family'.trim();
      if (displayName.isNotEmpty) {
        return OrcidProfile(orcidId: orcidId, displayName: displayName);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _readNestedValue(
      Map<String, dynamic> map, String outer, String inner) {
    final outerMap = map[outer] as Map<String, dynamic>?;
    return outerMap?[inner]?.toString();
  }

  static Future<List<OrcidProfile>> searchProfiles(String query) async {
    try {
      final url = Uri.parse(
          '$_apiBase/expanded-search?q=${Uri.encodeComponent(query)}&rows=10');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'PaperTracker/1.0',
        },
      );
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final expandedSearch =
          json['expanded-search'] as Map<String, dynamic>?;
      if (expandedSearch == null) return [];

      final results = expandedSearch['expanded-result'] as List<dynamic>?;
      if (results == null) return [];

      return results.map((result) {
        final r = result as Map<String, dynamic>;
        final givenNames = r['given-names'] ?? '';
        final familyNames = r['family-names'] ?? '';
        final displayName = '$givenNames $familyNames'.trim();
        final institutions = r['institution-name'] as List<dynamic>?;
        final institution = institutions != null && institutions.isNotEmpty
            ? institutions.first.toString()
            : null;

        return OrcidProfile(
          orcidId: r['orcid-id'],
          displayName: displayName,
          institution: institution,
        );
      }).toList();
    } catch (e) {
      debugPrint('ORCID search error: $e');
      return [];
    }
  }
}
