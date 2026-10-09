import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:app/APIService.dart';
import 'package:app/models/user_group_details.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// IMPORTANT: These values come from your realm-export file.
const String KEYCLOAK_ISSUER = String.fromEnvironment(
  'KEYCLOAK_ISSUER',
  defaultValue: 'http://localhost:8000/realms/polarforecast-web',
);
const String CLIENT_ID = 'polarforecast-gui';
const String REDIRECT_URI = String.fromEnvironment(
  'REDIRECT_URI',
  defaultValue: 'http://localhost:3000/',
);
const String POST_LOGOUT_REDIRECT_URI = String.fromEnvironment(
  'POST_LOGOUT_REDIRECT_URI',
  defaultValue: 'http://localhost:3000/',
);

class AuthService extends ChangeNotifier {
  String? accessToken;
  String? idToken;
  String? refreshToken;

  String? username;
  String? firstName;

  String? group;
  String? groupId;

  String? role; // 🔥 IMPORTANT (owner/admin/member)
  int? team;

  UserGroupInfo? groupInfo;

  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;

  final APIService _api = APIService();

  AuthService();

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  Future<void> init() async {
    idToken = html.window.localStorage['id_token'];
    accessToken = html.window.localStorage['access_token'];
    refreshToken = html.window.localStorage['refresh_token'];

    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    if (code != null) {
      final storedState = html.window.localStorage['pkce_state'];
      final codeVerifier = html.window.localStorage['pkce_code_verifier'];

      if (storedState != null && storedState == state && codeVerifier != null) {
        await _exchangeCodeForTokens(code, codeVerifier);

        html.window.history
            .replaceState(null, '', html.window.location.pathname);

        html.window.localStorage.remove('pkce_state');
        html.window.localStorage.remove('pkce_code_verifier');
      }
    }

    if (idToken != null && idToken!.isNotEmpty) {
      _parseIdToken();

      _loggedIn = true;
      notifyListeners();

      await _loadUserGroup(); // 🔥 FIXED: async-safe load AFTER username exists
    }
  }

  // ------------------------------------------------------------
  // LOAD GROUP FROM BACKEND
  // ------------------------------------------------------------
  Future<void> _loadUserGroup() async {
    if (username == null) return;

    try {
      final data = await _api.getUserGroup(username!);

      groupInfo = data;

      group = data.name;
      groupId = data.group_id;
      role = data.role;
    } catch (e) {
      groupInfo = null;
      group = null;
      groupId = null;
      role = null;
      print("Failed to load group: $e");
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------
  Future<void> login() async {
    final codeVerifier = _createCodeVerifier();
    final codeChallenge = _createCodeChallenge(codeVerifier);
    final state = _randomString(16);

    html.window.localStorage['pkce_code_verifier'] = codeVerifier;
    html.window.localStorage['pkce_state'] = state;

    final authEndpoint =
        '${KEYCLOAK_ISSUER.replaceAll(RegExp(r'/?$'), '')}/protocol/openid-connect/auth';

    final params = {
      'client_id': CLIENT_ID,
      'redirect_uri': REDIRECT_URI,
      'response_type': 'code',
      'scope': 'openid profile email offline_access',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      'prompt': 'consent',
    };

    final uri = Uri.parse(authEndpoint).replace(queryParameters: params);
    html.window.location.href = uri.toString();
  }

  // ------------------------------------------------------------
  // TOKEN EXCHANGE
  // ------------------------------------------------------------
  Future<void> _exchangeCodeForTokens(String code, String codeVerifier) async {
    final tokenEndpoint =
        '${KEYCLOAK_ISSUER.replaceAll(RegExp(r'/?$'), '')}/protocol/openid-connect/token';

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': REDIRECT_URI,
        'client_id': CLIENT_ID,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Token exchange failed: ${response.statusCode} ${response.body}');
    }

    final tokens = jsonDecode(response.body);

    accessToken = tokens['access_token'];
    idToken = tokens['id_token'];
    refreshToken = tokens['refresh_token'];

    if (accessToken != null) {
      html.window.localStorage['access_token'] = accessToken!;
    }
    if (idToken != null) {
      html.window.localStorage['id_token'] = idToken!;
    }
    if (refreshToken != null) {
      html.window.localStorage['refresh_token'] = refreshToken!;
    }

    _parseIdToken();
    _loggedIn = true;
    notifyListeners();

    await _loadUserGroup();
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> logout() async {
    html.window.localStorage.remove('access_token');
    html.window.localStorage.remove('id_token');
    html.window.localStorage.remove('refresh_token');

    final endSession =
        '${KEYCLOAK_ISSUER.replaceAll(RegExp(r'/?$'), '')}/protocol/openid-connect/logout'
        '?post_logout_redirect_uri=${Uri.encodeComponent(POST_LOGOUT_REDIRECT_URI)}'
        '${idToken != null ? '&id_token_hint=${Uri.encodeComponent(idToken!)}' : ''}';

    accessToken = null;
    idToken = null;
    refreshToken = null;

    username = null;
    firstName = null;
    group = null;
    groupId = null;
    role = null;
    groupInfo = null;

    _loggedIn = false;
    notifyListeners();

    html.window.location.href = endSession;
  }

  // ------------------------------------------------------------
  // ID TOKEN PARSE
  // ------------------------------------------------------------
  void _parseIdToken() {
    if (idToken == null) return;

    try {
      final parts = idToken!.split('.');
      if (parts.length != 3) return;

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));

      final claims = jsonDecode(payload);

      username = claims['preferred_username'] ?? claims['username'];
      firstName = claims['given_name'] ?? claims['name'];

      if (claims['teamNumber'] != null) {
        team = int.tryParse(claims['teamNumber'].toString());
      }
    } catch (e) {
      print("Error parsing ID token: $e");
    }
  }

  // ------------------------------------------------------------
  // ROLE HELPERS
  // ------------------------------------------------------------
  bool get isOwner => role == "owner";

  bool get isAdmin => role == "admin" || role == "owner";

  bool get isMember => role == "member";

  // ------------------------------------------------------------
  // REFRESH TOKEN
  // ------------------------------------------------------------
  Future<void> refreshTokens() async {
    if (refreshToken == null) return;

    final tokenEndpoint =
        '${KEYCLOAK_ISSUER.replaceAll(RegExp(r'/?$'), '')}/protocol/openid-connect/token';

    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken!,
          'client_id': CLIENT_ID,
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Refresh failed: ${response.body}");
      }

      final tokens = jsonDecode(response.body);

      accessToken = tokens['access_token'];
      idToken = tokens['id_token'];
      refreshToken = tokens['refresh_token'] ?? refreshToken;

      if (accessToken != null) {
        html.window.localStorage['access_token'] = accessToken!;
      }
      if (idToken != null) {
        html.window.localStorage['id_token'] = idToken!;
      }
      if (refreshToken != null) {
        html.window.localStorage['refresh_token'] = refreshToken!;
      }

      _parseIdToken();
      await _loadUserGroup();

      notifyListeners();
    } catch (e) {
      print("Refresh failed: $e");
      await logout();
    }
  }

  // ------------------------------------------------------------
  // PKCE HELPERS
  // ------------------------------------------------------------
  String _createCodeVerifier() {
    final rnd = html.window.crypto?.getRandomValues(Uint8List(32));
    return base64Url.encode(rnd! as List<int>).replaceAll('=', '');
  }

  String _createCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _randomString(int length) {
    final rnd = html.window.crypto?.getRandomValues(Uint8List(length));
    return base64Url.encode(rnd! as List<int>).replaceAll('=', '');
  }
}
