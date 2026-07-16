import 'orcid_name.dart';

class OrcidPerson {
  final OrcidName name;
  final String biography;
  final String country;
  final List<String> keywords;
  final List<String> websites;
  final List<String> externalIds;

  const OrcidPerson({
    required this.name,
    this.biography = '',
    this.country = '',
    this.keywords = const [],
    this.websites = const [],
    this.externalIds = const [],
  });

  factory OrcidPerson.fromJson(Map<String, dynamic> json) {
    final person = json['person'] as Map<String, dynamic>?;

    final name = OrcidName.fromJson(person ?? {});

    final bio = person?['biography'] as Map<String, dynamic>?;
    final biography = bio?['value']?.toString() ?? '';

    final countryMap = person?['country'] as Map<String, dynamic>?;
    final countryVal = countryMap?['value']?.toString() ?? '';

    final keywordsList = (person?['keywords'] as Map<String, dynamic>?)?['keyword'] as List<dynamic>?;
    final keywords = keywordsList
            ?.map((k) => (k as Map<String, dynamic>)['content']?.toString() ?? '')
            .where((k) => k.isNotEmpty)
            .toList() ??
        [];

    final websitesList = (person?['researcher-urls'] as Map<String, dynamic>?)?['researcher-url'] as List<dynamic>?;
    final websites = websitesList
            ?.map((w) => (w as Map<String, dynamic>)['url-name']?.toString() ?? '')
            .where((w) => w.isNotEmpty)
            .toList() ??
        [];

    final extIds = (person?['external-identifiers'] as Map<String, dynamic>?)?['external-identifier'] as List<dynamic>?;
    final externalIds = extIds
            ?.map((e) => (e as Map<String, dynamic>)['external-id-value']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    return OrcidPerson(
      name: name,
      biography: biography,
      country: countryVal,
      keywords: keywords,
      websites: websites,
      externalIds: externalIds,
    );
  }
}
