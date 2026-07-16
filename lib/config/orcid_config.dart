import 'package:flutter/foundation.dart' show kIsWeb;

class OrcidConfig {
  OrcidConfig._();

  static const String clientId = 'APP-7F58IEY5FIYOIQA1';
  static const String clientSecret = '1f2b490c-d0c5-48af-9637-86ec91981759';
  
  static String get redirectUri => kIsWeb 
      ? 'https://papercheck-2026.web.app/callback' 
      : 'http://127.0.0.1:57890/callback';

  static const String authorizationUrl = 'https://orcid.org/oauth/authorize';
  static const String tokenUrl = 'https://orcid.org/oauth/token';
  static const String apiBaseUrl = 'https://api.orcid.org/v3.0';
  static const String publicApiBaseUrl = 'https://pub.orcid.org/v3.0';
  
  static const List<String> scopes = [
    '/authenticate',
  ];
}
