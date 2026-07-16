import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/orcid/orcid_record.dart';
import 'package:paper_tracker/services/notification_service.dart';
import 'package:paper_tracker/services/orcid_api_service.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

class AcademicProfileRepository {
  final OrcidApiService _orcidApi;
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  AcademicProfileRepository({
    OrcidApiService? orcidApi,
    FirebaseDatabase? db,
    FirebaseAuth? auth,
  })  : _orcidApi = orcidApi ?? OrcidApiService(),
        _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const _cachePrefix = 'academic_profile_';
  static const _cacheTimePrefix = 'academic_profile_time_';
  static const _cacheDuration = Duration(hours: 24);

  Future<OrcidRecord> fetchProfile(String orcidId) async {
    final cached = await _getCached(orcidId);
    if (cached != null) return cached;

    try {
      return await _fetchAndCache(orcidId);
    } catch (e) {
      final backup = await _fetchFromFirebase();
      if (backup != null) {
        await _setCached(orcidId, backup);
        return backup;
      }
      rethrow;
    }
  }

  Future<OrcidRecord> fetchProfileFresh(String orcidId) async {
    try {
      return await _fetchAndCache(orcidId);
    } catch (e) {
      final backup = await _fetchFromFirebase();
      if (backup != null) {
        await _setCached(orcidId, backup);
        return backup;
      }
      rethrow;
    }
  }

  Future<OrcidRecord> _fetchAndCache(String orcidId) async {
    final record = await _orcidApi.fetchRecord(orcidId);
    await _setCached(orcidId, record);
    _backupToFirebase(record);
    return record;
  }

  Future<void> _backupToFirebase(OrcidRecord record) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final data = _recordToJson(record);
      await _db.ref('users/$uid/academic_profile').set(data);
    } catch (e) {
      debugPrint('DEBUG REPO: Failed to backup academic profile to Firebase: $e');
    }
  }

  Future<OrcidRecord?> _fetchFromFirebase() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final snapshot = await _db.ref('users/$uid/academic_profile').get();
      if (snapshot.exists && snapshot.value != null) {
        final map = jsonDecode(jsonEncode(snapshot.value)) as Map<String, dynamic>;
        return OrcidRecord.fromJson(map);
      }
    } catch (e) {
      debugPrint('DEBUG REPO: Failed to retrieve academic profile from Firebase: $e');
    }
    return null;
  }

  Future<bool> isAuthorized() => OrcidAuthService.hasValidToken();

  Future<bool> disconnect() async {
    await OrcidAuthService.disconnect();
    return true;
  }

  Future<OrcidRecord?> getCached(String orcidId) async {
    return _getCached(orcidId);
  }

  Future<bool> isCacheExpired(String orcidId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTime = prefs.getInt('$_cacheTimePrefix$orcidId');
    if (cachedTime == null) return true;
    final cachedDate = DateTime.fromMillisecondsSinceEpoch(cachedTime);
    return DateTime.now().difference(cachedDate) > _cacheDuration;
  }

  Future<void> clearCache(String orcidId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$orcidId');
    await prefs.remove('$_cacheTimePrefix$orcidId');
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimePrefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<OrcidRecord?> _getCached(String orcidId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('$_cachePrefix$orcidId');
    if (cachedJson == null) return null;

    final cachedTime = prefs.getInt('$_cacheTimePrefix$orcidId');
    if (cachedTime != null) {
      final cachedDate = DateTime.fromMillisecondsSinceEpoch(cachedTime);
      if (DateTime.now().difference(cachedDate) > _cacheDuration) {
        return null;
      }
    }
    try {
      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      if (!json.containsKey('activities-summary') || !json.containsKey('orcid-identifier')) {
        return null; // Discard old cache format
      }
      final personMap = json['person'] as Map<String, dynamic>?;
      final nameMap = personMap?['name'] as Map<String, dynamic>?;
      if (nameMap != null && nameMap.containsKey('name')) {
        return null; // Discard cache with broken double name key
      }
      return OrcidRecord.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setCached(String orcidId, OrcidRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_recordToJson(record));
    await prefs.setString('$_cachePrefix$orcidId', json);
    await prefs.setInt(
      '$_cacheTimePrefix$orcidId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> _recordToJson(OrcidRecord record) {
    return {
      'orcid-identifier': {
        'path': record.orcidId,
      },
      'person': {
        'name': {
          'given-names': {'value': record.person.name.givenNames},
          'family-name': {'value': record.person.name.familyName},
          'credit-name': {'value': record.person.name.creditName},
        },
        'biography': {'value': record.person.biography},
        'country': {'value': record.person.country},
        'keywords': {
          'keyword': record.person.keywords
              .map((k) => {'content': k})
              .toList(),
        },
        'researcher-urls': {
          'researcher-url': record.person.websites
              .map((w) => {'url-name': w})
              .toList(),
        },
        'external-identifiers': {
          'external-identifier': record.person.externalIds
              .map((e) => {'external-id-value': e})
              .toList(),
        },
      },
      'activities-summary': {
        'employments': {
          'affiliation-group': record.employments.map((e) => {
            'summaries': [
              {
                'employment-summary': {
                  'department-name': e.departmentName,
                  'role-title': e.roleTitle,
                  'organization': {
                    'name': e.organizationName,
                    'address': {
                      'city': e.city,
                      'region': e.region,
                      'country': e.country,
                    },
                  },
                  'start-date': e.startDate != null ? _dateToMap(e.startDate!) : null,
                  'end-date': e.endDate != null ? _dateToMap(e.endDate!) : null,
                }
              }
            ]
          }).toList(),
        },
        'educations': {
          'affiliation-group': record.educations.map((e) => {
            'summaries': [
              {
                'education-summary': {
                  'department-name': e.departmentName,
                  'role-title': e.roleTitle,
                  'organization': {
                    'name': e.organizationName,
                    'address': {
                      'city': e.city,
                      'country': e.country,
                    },
                  },
                  'start-date': e.startDate != null ? _dateToMap(e.startDate!) : null,
                  'end-date': e.endDate != null ? _dateToMap(e.endDate!) : null,
                }
              }
            ]
          }).toList(),
        },
        'works': {
          'group': record.works.map((w) => {
            'work-summary': [
              {
                'title': {
                  'title': {'value': w.title},
                  'subtitle': {'value': w.subtitle},
                },
                'journal-title': {'value': w.journalTitle},
                'publication-date': {
                  'year': {'value': w.publicationYear.toString()},
                },
                'type': w.type,
                'external-ids': {
                  'external-id': [
                    if (w.doi.isNotEmpty)
                      {
                        'external-id-type': 'doi',
                        'external-id-value': w.doi,
                      }
                  ],
                },
                'url': w.url,
              }
            ]
          }).toList(),
        },
        'fundings': {
          'group': record.fundings.map((f) => {
            'funding-summary': [
              {
                'title': {
                  'title': {'value': f.title},
                },
                'organization': {'name': f.organizationName},
                'type': f.type,
                'start-date': f.startDate != null ? _dateToMap(f.startDate!) : null,
                'end-date': f.endDate != null ? _dateToMap(f.endDate!) : null,
                'amount': f.amount.isNotEmpty ? {'value': f.amount} : null,
              }
            ]
          }).toList(),
        },
        'qualifications': {
          'affiliation-group': record.qualifications.map((q) => {
            'summaries': [
              {
                'qualification-summary': {
                  'role-title': q,
                }
              }
            ]
          }).toList(),
        },
        'memberships': {
          'affiliation-group': record.memberships.map((m) => {
            'summaries': [
              {
                'membership-summary': {
                  'role-title': m,
                }
              }
            ]
          }).toList(),
        },
      }
    };
  }

  Map<String, dynamic> _dateToMap(DateTime date) {
    return {
      'year': {'value': date.year.toString()},
      'month': {'value': date.month.toString()},
      'day': {'value': date.day.toString()},
    };
  }

  Future<void> checkForNewPublications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt('orcid_last_notify_check');
      final now = DateTime.now();

      if (lastCheckTime != null) {
        final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
        if (now.difference(lastCheck) < const Duration(days: 2)) {
          return;
        }
      }

      final token = await OrcidAuthService.getStoredToken();
      final orcidId = token?.orcidId ?? '';
      if (orcidId.isEmpty) return;

      final oldRecord = await fetchProfile(orcidId);
      final newRecord = await _orcidApi.fetchRecord(orcidId);

      final oldWorks = oldRecord.works;
      final newWorks = newRecord.works;

      final newPapers = <String>[];
      for (final nw in newWorks) {
        final alreadyExists = oldWorks.any((ow) => ow.title.trim().toLowerCase() == nw.title.trim().toLowerCase());
        if (!alreadyExists) {
          newPapers.add(nw.title);
        }
      }

      if (newPapers.isNotEmpty) {
        final body = newPapers.length == 1
            ? 'New Paper: "${newPapers.first}"'
            : '${newPapers.length} new publications added to ORCID.';

        await NotificationService().showNotification(
          id: now.millisecondsSinceEpoch.remainder(100000),
          title: 'New Publication on ORCID',
          body: body,
          payload: '/academic-profile',
        );

        await _setCached(orcidId, newRecord);
        _backupToFirebase(newRecord);
      }

      await prefs.setInt('orcid_last_notify_check', now.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('DEBUG REPO: checkForNewPublications error: $e');
    }
  }
}
