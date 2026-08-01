import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static final _secureStorage = const FlutterSecureStorage();

  static OrcidToken? _cachedToken;

  static Future<OrcidToken?> getStoredToken() async {
    if (_cachedToken != null && !_cachedToken!.isExpired) {
      return _cachedToken;
    }
    final raw = await _readToken();
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

  // flutter_secure_storage's web implementation (WebCrypto-backed) can throw
  // in some browsers, which would otherwise produce an unhandled exception (a
  // gray screen in release builds). On web the token is not meaningfully more
  // secure in secure storage than in SharedPreferences anyway (both are
  // client-side and the key is local), so we use SharedPreferences there.
  static Future<String?> _readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    }
    return _secureStorage.read(key: _tokenKey);
  }

  static Future<void> _writeToken(String json) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, json);
    } else {
      await _secureStorage.write(key: _tokenKey, value: json);
    }
  }

  static Future<void> saveToken(OrcidToken token) async {
    await _writeToken(jsonEncode(token.toJson()));
    await _saveLinkedIdentity(token.orcidId, name: token.name);
  }

  static Future<void> _clearToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } else {
      await _secureStorage.delete(key: _tokenKey);
    }
    _cachedToken = null;
  }

  // --- Web implicit OAuth (client-only, no CORS) ---
  //
  // ORCID deliberately blocks CORS on its OAuth token endpoint
  // (https://orcid.org/oauth/token), so a browser can never exchange an
  // authorization code there. On web we therefore use ORCID's implicit flow
  // (response_type=token), which is designed for single-page apps and returns
  // the access token directly in the redirect URL fragment. Those tokens are
  // short-lived with no refresh token, so the linked ORCID iD is also
  // persisted separately (in plain SharedPreferences) and the cached profile
  // remains viewable after the token lapses.

  static const _linkedIdKey = 'orcid_linked_id';
  static const _linkedNameKey = 'orcid_linked_name';
  static const _webStateKey = 'orcid_web_state';

  static Future<String?> getLinkedOrcidId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_linkedIdKey);
  }

  static Future<String?> getLinkedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_linkedNameKey);
  }

  static Future<void> _saveLinkedIdentity(
    String orcidId, {
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_linkedIdKey, orcidId);
    if (name != null) {
      await prefs.setString(_linkedNameKey, name);
    }
  }

  static Future<void> _saveWebState(String state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webStateKey, state);
  }

  static Future<String?> _takeWebState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = prefs.getString(_webStateKey);
    await prefs.remove(_webStateKey);
    return state;
  }

  static Future<String> buildWebAuthorizationUrl() async {
    final state = generateCodeVerifier().substring(0, 16);
    await _saveWebState(state);

    final params = {
      'response_type': 'token',
      'client_id': OrcidConfig.clientId,
      'redirect_uri': OrcidConfig.redirectUri,
      'scope': OrcidConfig.scopes.join(' '),
      'state': state,
    };

    return '${OrcidConfig.authorizationUrl}?${Uri(queryParameters: params).query}';
  }

  static Future<OrcidAuthResult> completeWebCallback(String redirectUrl) async {
    final uri = Uri.parse(redirectUrl);
    final params = uri.fragment.isNotEmpty
        ? Uri.splitQueryString(uri.fragment)
        : uri.queryParameters;

    if (params['error'] != null) {
      return OrcidAuthResult(
        error: params['error_description'] ?? params['error']!,
      );
    }

    final expectedState = await _takeWebState();
    final returnedState = params['state'];
    if (expectedState != null &&
        returnedState != null &&
        returnedState != expectedState) {
      return OrcidAuthResult(error: 'State mismatch. Please try again.');
    }

    final accessToken = params['access_token'];
    if (accessToken == null || accessToken.isEmpty) {
      return OrcidAuthResult(error: 'No access token returned by ORCID.');
    }

    final expiresIn = int.tryParse(params['expires_in'] ?? '') ?? 600;
    final orcidId = params['orcid'] ?? _orcidIdFromIdToken(params['id_token']);
    if (orcidId == null || orcidId.isEmpty) {
      return OrcidAuthResult(error: 'Could not determine your ORCID iD.');
    }

    final token = OrcidToken(
      accessToken: accessToken,
      orcidId: orcidId,
      name: params['name'] ?? _nameFromIdToken(params['id_token']),
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );

    // Persist the linked iD first so the (short-lived) profile stays viewable
    // even if persisting the web token itself fails.
    try {
      await _saveLinkedIdentity(token.orcidId, name: token.name);
    } catch (e) {
      debugPrint('ORCID: could not persist linked iD: $e');
    }

    try {
      await saveToken(token);
    } catch (e) {
      debugPrint('ORCID: could not persist token (linked iD kept): $e');
    }

    _cachedToken = token;
    return OrcidAuthResult(token: token);
  }

  static String? _orcidIdFromIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    try {
      final sub = _decodeJwtPayload(idToken)['sub'] as String?;
      return (sub != null && sub.startsWith('0000-')) ? sub : null;
    } catch (_) {
      return null;
    }
  }

  static String? _nameFromIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    try {
      return _decodeJwtPayload(idToken)['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _decodeJwtPayload(String idToken) {
    final parts = idToken.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT');
    }
    final normalized = base64Url.normalize(parts[1]);
    return jsonDecode(utf8.decode(base64Url.decode(normalized)))
        as Map<String, dynamic>;
  }

  static Future<void> disconnect() async {
    await _clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_linkedIdKey);
    await prefs.remove(_linkedNameKey);
    await prefs.remove(_webStateKey);
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
