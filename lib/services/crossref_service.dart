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
      final resMap = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;
      final data = resMap?['message'] as Map<String, dynamic>?;
      if (data == null) return null;

      int year = 0;
      final pubPrint = data['published-print'] as Map<String, dynamic>?;
      final dateParts = pubPrint?['date-parts'] as List?;
      if (dateParts != null && dateParts.isNotEmpty) {
        final firstDate = dateParts.first as List?;
        if (firstDate != null && firstDate.isNotEmpty) {
          year = (firstDate.first as num?)?.toInt() ?? 0;
        }
      }

      return CrossrefDoiMetadata(
        title: (data['title'] as List?)?.first?.toString() ?? '',
        journal: data['container-title']?.toString() ?? '',
        year: year,
        doi: doi,
        citationCount: (data['is-referenced-by-count'] as num?)?.toInt() ?? 0,
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
