import 'package:dio/dio.dart';
import 'package:paper_tracker/config/orcid_config.dart';
import 'package:paper_tracker/models/orcid/orcid_record.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

class OrcidApiService {
  final Dio _dio;
  final bool _useAuth;

  OrcidApiService({Dio? dio, bool useAuth = false})
      : _useAuth = useAuth,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: useAuth ? OrcidConfig.apiBaseUrl : OrcidConfig.publicApiBaseUrl,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'PaperTracker/1.0',
              },
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  Future<OrcidRecord> fetchRecord(String orcidId) async {
    if (_useAuth) {
      final token = await OrcidAuthService.getAccessToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }
    }
    final response = await _dio.get('/$orcidId/record');
    if (response.statusCode == 200 && response.data is Map) {
      return OrcidRecord.fromJson(response.data as Map<String, dynamic>);
    }
    throw OrcidApiException(
      'Unexpected response: HTTP ${response.statusCode}',
    );
  }
}

class OrcidApiException implements Exception {
  final String message;
  const OrcidApiException(this.message);

  @override
  String toString() => message;
}
