import 'package:dio/dio.dart';

class SemanticScholarMetrics {
  final int citationCount;
  final int influentialCitationCount;
  final int hIndex;
  final List<SemanticScholarPaper> topPapers;

  const SemanticScholarMetrics({
    this.citationCount = 0,
    this.influentialCitationCount = 0,
    this.hIndex = 0,
    this.topPapers = const [],
  });
}

class SemanticScholarPaper {
  final String title;
  final int year;
  final int citationCount;
  final String doi;

  const SemanticScholarPaper({
    this.title = '',
    this.year = 0,
    this.citationCount = 0,
    this.doi = '',
  });
}

class SemanticScholarService {
  final Dio _dio;

  SemanticScholarService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.semanticscholar.org/graph/v1',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<SemanticScholarMetrics?> fetchAuthor(String orcidId) async {
    try {
      final response = await _dio.get(
        '/author/search',
        queryParameters: {
          'query': orcidId,
          'limit': 1,
          'fields': 'citationCount,hIndex,paperCount',
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final results = data?['data'] as List?;
      if (results == null || results.isEmpty) return null;

      final authorId = results.first['authorId'];
      if (authorId == null) return null;

      final detailResponse = await _dio.get(
        '/author/$authorId',
        queryParameters: {
          'fields': 'citationCount,hIndex,influentialCitationCount,papers.title,papers.year,papers.citationCount,papers.externalIds',
        },
      );
      final detail = detailResponse.data as Map<String, dynamic>?;
      if (detail == null) return null;

      final papersList = (detail['papers'] as List?)?.map((p) {
            final pMap = p as Map<String, dynamic>;
            final extIds = pMap['externalIds'] as Map<String, dynamic>?;
            return SemanticScholarPaper(
              title: pMap['title']?.toString() ?? '',
              year: pMap['year'] ?? 0,
              citationCount: pMap['citationCount'] ?? 0,
              doi: extIds?['DOI']?.toString() ?? '',
            );
          }).toList() ??
          [];

      return SemanticScholarMetrics(
        citationCount: detail['citationCount'] ?? 0,
        influentialCitationCount: detail['influentialCitationCount'] ?? 0,
        hIndex: detail['hIndex'] ?? 0,
        topPapers: papersList.take(5).toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
