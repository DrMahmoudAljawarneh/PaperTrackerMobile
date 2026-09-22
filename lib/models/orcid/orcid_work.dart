class OrcidWork {
  final String title;
  final String subtitle;
  final String journalTitle;
  final int publicationYear;
  final String doi;
  final String type;
  final String url;

  const OrcidWork({
    this.title = '',
    this.subtitle = '',
    this.journalTitle = '',
    this.publicationYear = 0,
    this.doi = '',
    this.type = '',
    this.url = '',
  });

  factory OrcidWork.fromJson(Map<String, dynamic> json) {
    final titleMap = json['title'] as Map<String, dynamic>?;
    final innerTitle = titleMap?['title'] as Map<String, dynamic>?;
    final titleVal = innerTitle?['value']?.toString() ?? '';
    final innerSubtitle = titleMap?['subtitle'] as Map<String, dynamic>?;
    final subtitleVal = innerSubtitle?['value']?.toString() ?? '';

    final journalMap = json['journal-title'] as Map<String, dynamic>?;
    final journalVal = journalMap?['value']?.toString() ?? '';

    final pubDate = json['publication-date'] as Map<String, dynamic>?;
    final yearMap = pubDate?['year'] as Map<String, dynamic>?;
    final year = int.tryParse(yearMap?['value']?.toString() ?? '') ?? 0;

    final extIds = json['external-ids'] as Map<String, dynamic>?;
    final extIdList = extIds?['external-id'] as List<dynamic>?;
    String doiVal = '';
    if (extIdList != null) {
      for (final item in extIdList) {
        if (item is Map) {
          if (item['external-id-type']?.toString() == 'doi') {
            doiVal = item['external-id-value']?.toString() ?? '';
            break;
          }
        }
      }
    }

    return OrcidWork(
      title: titleVal,
      subtitle: subtitleVal,
      journalTitle: journalVal,
      publicationYear: year,
      doi: doiVal,
      type: json['type']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}
