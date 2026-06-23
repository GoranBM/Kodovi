import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import 'web_redirect_stub.dart'
    if (dart.library.html) 'web_redirect_web.dart' as web;

class AuthService {
  static const _clientId = 'da433c5a-5d93-4b9c-8e03-017ecddd4665';

  // Mobile: custom scheme registriran u Azure pod "Mobile and desktop applications"
  static const _mobileRedirect = 'com.example.qrkontakt://oauth2redirect';

  // Web: dinamičan origin bez slasha → Azure "http://localhost" prihvaća sve portove
  static String get _webRedirect => Uri.base.origin;

  static const _tenant = '94adceb8-bf15-46c0-a4a5-eda6e63b4cf3';
  static const _tokenEndpoint =
      'https://login.microsoftonline.com/$_tenant/oauth2/v2.0/token';

  static const _scopes = [
    'openid', 'profile', 'email', 'offline_access',
    'Files.ReadWrite', 'User.Read',
  ];

  static final _storage = FlutterSecureStorage();
  static const _accessKey = 'ms_access_token';
  static const _refreshKey = 'ms_refresh_token';

  // localStorage ključevi za PKCE (privremeni, ne trebaju enkripciju)
  static const _lsVerifier = 'pkce_v';
  static const _lsRedirect = 'pkce_r';

  // ── PKCE ─────────────────────────────────────────────────────────────────

  static String _makeVerifier() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _makeChallenge(String verifier) {
    final hash = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  static Future<bool> login() =>
      kIsWeb ? _loginWeb() : _loginMobile();

  static Future<bool> _loginWeb() async {
    final verifier = _makeVerifier();
    final redirectUri = _webRedirect;

    // Koristi localStorage direktno — flutter_secure_storage gubi podatke
    // kada browser navigira na drugi origin (Microsoft login)
    web.saveLocal(_lsVerifier, verifier);
    web.saveLocal(_lsRedirect, redirectUri);

    final authUrl = Uri.https(
      'login.microsoftonline.com',
      '/$_tenant/oauth2/v2.0/authorize',
      {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': _scopes.join(' '),
        'code_challenge': _makeChallenge(verifier),
        'code_challenge_method': 'S256',
      },
    ).toString();

    web.navigateTo(authUrl); // cijeli browser odlazi na Microsoft login
    return false; // nikad se ne dostiže
  }

  static Future<bool> _loginMobile() async {
    final verifier = _makeVerifier();

    final authUrl = Uri.https(
      'login.microsoftonline.com',
      '/$_tenant/oauth2/v2.0/authorize',
      {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _mobileRedirect,
        'scope': _scopes.join(' '),
        'code_challenge': _makeChallenge(verifier),
        'code_challenge_method': 'S256',
      },
    ).toString();

    final callbackUrl = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: 'com.example.qrkontakt',
    );

    final code = Uri.parse(callbackUrl).queryParameters['code'];
    if (code == null) return false;

    return _exchangeCode(
        code: code, verifier: verifier, redirectUri: _mobileRedirect);
  }

  // ── Web callback — poziva se pri svakom pokretanju web appa ──────────────

  static Future<bool> handleWebCallback() async {
    if (!kIsWeb) return false;

    final code = Uri.base.queryParameters['code'];
    if (code == null) return false;

    final verifier = web.readLocal(_lsVerifier);
    final redirectUri = web.readLocal(_lsRedirect);

    if (verifier == null || redirectUri == null) {
      debugPrint('PKCE data missing — verifier=$verifier, redirect=$redirectUri');
      return false;
    }

    web.removeLocal(_lsVerifier);
    web.removeLocal(_lsRedirect);
    // cleanUrl() namjerno izostavljen — izaziva Flutter Web history assertion error

    debugPrint('Exchanging code. redirect_uri=$redirectUri');
    return _exchangeCode(
        code: code, verifier: verifier, redirectUri: redirectUri);
  }

  // ── Token exchange ────────────────────────────────────────────────────────

  static Future<bool> _exchangeCode({
    required String code,
    required String verifier,
    required String redirectUri,
  }) async {
    final res = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'code': code,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
      },
    );

    if (res.statusCode != 200) {
      debugPrint('Token exchange ${res.statusCode}: ${res.body}');
      return false;
    }

    final json = jsonDecode(res.body);
    await _storage.write(key: _accessKey, value: json['access_token']);
    if (json['refresh_token'] != null) {
      await _storage.write(key: _refreshKey, value: json['refresh_token']);
    }
    return true;
  }

  // ── Token refresh ─────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken != null) {
      try {
        final res = await http.post(
          Uri.parse(_tokenEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'client_id': _clientId,
            'refresh_token': refreshToken,
            'grant_type': 'refresh_token',
            'scope': _scopes.join(' '),
          },
        );
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          await _storage.write(key: _accessKey, value: json['access_token']);
          if (json['refresh_token'] != null) {
            await _storage.write(
                key: _refreshKey, value: json['refresh_token']);
          }
          return json['access_token'];
        }
      } catch (_) {}
    }
    return _storage.read(key: _accessKey);
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  static Future<bool> get isLoggedIn async {
    final refresh = await _storage.read(key: _refreshKey);
    final access = await _storage.read(key: _accessKey);
    return refresh != null || access != null;
  }

  static Future<void> logout() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
