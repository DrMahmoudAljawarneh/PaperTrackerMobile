import 'package:dio/dio.dart';

class CrossrefDoiMetadata {
  final String title;
  final String journal;
  final int year;
  final String doi;
  final int citationCount;

  const CrossrefDoiMetadata({
    this.title = '',
    this.journal = '',
    this.year = 0,
    this.doi = '',
    this.citationCount = 0,
  });
}

class CrossrefService {
  final Dio _dio;

  CrossrefService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.crossref.org',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'User-Agent': 'PaperTracker/1.0'},
            ));

  Future<CrossrefDoiMetadata?> fetchDoi(String doi) async {
    try {
      final response = await _dio.get('/works/$doi');
      final data = response.data?['message'] as Map<String, dynamic>?;
      if (data == null) return null;

      return CrossrefDoiMetadata(
        title: (data['title'] as List?)?.first?.toString() ?? '',
        journal: data['container-title']?.toString() ?? '',
        year: data['published-print']?['date-parts']?.first?.first ?? 0,
        doi: doi,
        citationCount: data['is-referenced-by-count'] ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> fetchCitationCount(String doi) async {
    final meta = await fetchDoi(doi);
    return meta?.citationCount ?? 0;
  }
}
