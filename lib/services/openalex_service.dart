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
      final resMap = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;
      final results = resMap?['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final firstResult = results.first as Map<String, dynamic>?;
        return firstResult?['id']?.toString();
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
      final works = (data['works_count'] as num?)?.toInt() ?? 0;
      final citedBy = (data['cited_by_count'] as num?)?.toInt() ?? 0;
      final h = (summary?['h_index'] as num?)?.toDouble() ?? 0.0;
      final i10 = (summary?['i10_index'] as num?)?.toDouble() ?? 0.0;

      return OpenAlexAuthorMetrics(
        worksCount: works,
        citedByCount: citedBy,
        hIndex: h,
        i10Index: i10,
      );
    } catch (_) {
      return const OpenAlexAuthorMetrics();
    }
  }
}
