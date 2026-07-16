import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paper_tracker/config/orcid_config.dart';

class OrcidToken {
  final String accessToken;
  final String? refreshToken;
  final String orcidId;
  final String? name;
  final DateTime expiresAt;

  OrcidToken({
    required this.accessToken,
    this.refreshToken,
    required this.orcidId,
    this.name,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'orcid': orcidId,
        'name': name,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory OrcidToken.fromJson(Map<String, dynamic> json) => OrcidToken(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
        orcidId: json['orcid'] as String,
        name: json['name'] as String?,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}

class OrcidAuthResult {
  final OrcidToken? token;
  final String? error;

  OrcidAuthResult({this.token, this.error});

  bool get isSuccess => token != null && error == null;
}

class AuthorizationRequest {
  final String url;
  final String codeVerifier;
  final String state;

  const AuthorizationRequest({
    required this.url,
    required this.codeVerifier,
    required this.state,
  });
}

class OrcidAuthService {
  static const _tokenKey = 'orcid_token';

  static OrcidToken? _cachedToken;

  static Future<OrcidToken?> getStoredToken() async {
    if (_cachedToken != null && !_cachedToken!.isExpired) {
      return _cachedToken;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tokenKey);
    if (raw == null) return null;
    try {
      final token = OrcidToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (token.isExpired) {
        if (token.refreshToken != null) {
          final refreshed = await _refreshToken(token.refreshToken!);
          if (refreshed != null) {
            _cachedToken = refreshed;
            return refreshed;
          }
        }
        await _clearToken();
        return null;
      }
      _cachedToken = token;
      return token;
    } catch (_) {
      await _clearToken();
      return null;
    }
  }

  static Future<bool> hasValidToken() async {
    final token = await getStoredToken();
    return token != null && !token.isExpired;
  }

  static Future<String?> getAccessToken() async {
    final token = await getStoredToken();
    return token?.accessToken;
  }

  static String generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static AuthorizationRequest prepareAuthorization() {
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final state = generateCodeVerifier().substring(0, 16);

    final params = {
      'response_type': 'code',
      'client_id': OrcidConfig.clientId,
      'redirect_uri': OrcidConfig.redirectUri,
      'scope': OrcidConfig.scopes.join(' '),
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    };

    final url = '${OrcidConfig.authorizationUrl}?${Uri(queryParameters: params).query}';

    return AuthorizationRequest(
      url: url,
      codeVerifier: codeVerifier,
      state: state,
    );
  }

  static Future<OrcidAuthResult> completeAuthorization(
    String redirectUrl,
    AuthorizationRequest request,
  ) async {
    try {
      final uri = Uri.parse(redirectUrl);
      final queryParams = uri.queryParameters;

      if (queryParams['state'] != request.state) {
        return OrcidAuthResult(error: 'State mismatch. Please try again.');
      }

      final code = queryParams['code'];
      if (code == null) {
        return OrcidAuthResult(
          error: queryParams['error_description'] ?? 'Authorization denied.',
        );
      }

      final token = await _exchangeCode(code, request.codeVerifier);
      if (token == null) {
        return OrcidAuthResult(error: 'Failed to exchange authorization code for token.');
      }

      await saveToken(token);
      _cachedToken = token;
      return OrcidAuthResult(token: token);
    } catch (e) {
      return OrcidAuthResult(error: 'Authorization failed: $e');
    }
  }

  static Future<OrcidToken?> _exchangeCode(String code, String codeVerifier) async {
    try {
      print('DEBUG ORCID: Exchanging code. ClientID: ${OrcidConfig.clientId}, RedirectURI: ${OrcidConfig.redirectUri}');
      final response = await http.post(
        Uri.parse(OrcidConfig.tokenUrl),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': OrcidConfig.clientId,
          'client_secret': OrcidConfig.clientSecret,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': OrcidConfig.redirectUri,
          'code_verifier': codeVerifier,
        },
      );

      print('DEBUG ORCID: Exchange response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('DEBUG ORCID: Exchange failed response body: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final expiresIn = data['expires_in'] as int? ?? 600;
      return OrcidToken(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
        orcidId: data['orcid'] as String,
        name: data['name'] as String?,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
    } catch (e, s) {
      print('DEBUG ORCID: Exception during code exchange: $e');
      print(s);
      return null;
    }
  }

  static Future<OrcidToken?> _refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(OrcidConfig.tokenUrl),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': OrcidConfig.clientId,
          'client_secret': OrcidConfig.clientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': OrcidConfig.scopes.join(' '),
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final expiresIn = data['expires_in'] as int? ?? 600;
      final token = OrcidToken(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String? ?? refreshToken,
        orcidId: data['orcid'] as String,
        name: data['name'] as String?,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
      await saveToken(token);
      _cachedToken = token;
      return token;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveToken(OrcidToken token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jsonEncode(token.toJson()));
  }

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _cachedToken = null;
  }

  static Future<void> disconnect() async {
    await _clearToken();
  }

  static Future<OrcidAuthResult> refreshCurrentToken() async {
    final token = _cachedToken;
    if (token == null) {
      return OrcidAuthResult(error: 'No token to refresh.');
    }
    if (token.refreshToken == null) {
      return OrcidAuthResult(error: 'No refresh token available.');
    }
    final refreshed = await _refreshToken(token.refreshToken!);
    if (refreshed == null) {
      return OrcidAuthResult(error: 'Failed to refresh token.');
    }
    return OrcidAuthResult(token: refreshed);
  }
}
