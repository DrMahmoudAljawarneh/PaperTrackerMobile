import 'package:dio/dio.dart';

class OpenAlexAuthorMetrics {
  final int worksCount;
  final int citedByCount;
  final double hIndex;
  final double i10Index;

  const OpenAlexAuthorMetrics({
    this.worksCount = 0,
    this.citedByCount = 0,
    this.hIndex = 0,
    this.i10Index = 0,
  });
}

class OpenAlexService {
  final Dio _dio;

  OpenAlexService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.openalex.org',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<String?> findAuthorId(String orcidId) async {
    try {
      final response = await _dio.get('/authors', queryParameters: {
        'filter': 'orcid:$orcidId',
      });
      final results = response.data?['results'] as List?;
      if (results != null && results.isNotEmpty) {
        return results.first['id']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<OpenAlexAuthorMetrics> fetchMetrics(String authorId) async {
    try {
      final response = await _dio.get('/authors/$authorId');
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return const OpenAlexAuthorMetrics();

      final summary = data['summary_stats'] as Map<String, dynamic>?;
      return OpenAlexAuthorMetrics(
        worksCount: data['works_count'] ?? 0,
        citedByCount: data['cited_by_count'] ?? 0,
        hIndex: (summary?['h_index'] ?? 0).toDouble(),
        i10Index: (summary?['i10_index'] ?? 0).toDouble(),
      );
    } catch (_) {
      return const OpenAlexAuthorMetrics();
    }
  }
}
