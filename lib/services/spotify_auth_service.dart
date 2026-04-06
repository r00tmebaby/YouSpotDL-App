import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';

class SpotifyAuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  HttpServer? _server;

  String? get accessToken => _accessToken;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  bool get isAuthenticated =>
      _accessToken != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  Future<void> loadSavedTokens() async {
    _accessToken = await _storage.read(key: 'spotify_access_token');
    _refreshToken = await _storage.read(key: 'spotify_refresh_token');
    final expiresStr = await _storage.read(key: 'spotify_expires_at');
    if (expiresStr != null) {
      _expiresAt = DateTime.fromMillisecondsSinceEpoch(int.parse(expiresStr));
    }
  }

  Future<void> _closeServer() async {
    if (_server != null) {
      try {
        await _server!.close(force: true);
      } catch (_) {}
      _server = null;
    }
  }

  Future<void> authenticate({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    // Always clean up any leftover server first
    await _closeServer();

    // Start local server to catch callback
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, defaultOAuthPort);
    } catch (e) {
      throw Exception('Port $defaultOAuthPort is already in use. Close any previous auth attempts and try again.');
    }

    final authUrl = Uri.parse(spotifyAuthEndpoint).replace(queryParameters: {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': spotifyScopes,
    });

    final launched = await launchUrl(authUrl);
    if (!launched) {
      await _closeServer();
      throw Exception('Could not open browser. Please check your browser settings.');
    }

    try {
      // Wait for the callback with a 2-minute timeout
      final request = await _server!.first.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception('Authentication timed out. Browser was closed without completing login.');
        },
      );

      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];

      // Respond to browser
      request.response
        ..statusCode = 200
        ..headers.set('Content-Type', 'text/html')
        ..write('<html><body><h1>Authentication successful! You can close this tab.</h1></body></html>')
        ..close();

      if (error != null) {
        throw Exception('Spotify auth error: $error');
      }
      if (code == null) {
        throw Exception('No auth code received from Spotify');
      }

      // Exchange code for tokens
      await _exchangeCode(code, clientId, clientSecret, redirectUri);
    } finally {
      // Always close the server, whether success or failure
      await _closeServer();
    }
  }

  Future<void> _exchangeCode(
    String code,
    String clientId,
    String clientSecret,
    String redirectUri,
  ) async {
    final response = await http.post(
      Uri.parse(spotifyTokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Token exchange failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await _storeTokens(data);
  }

  Future<void> refreshIfNeeded({
    required String clientId,
    required String clientSecret,
  }) async {
    if (isAuthenticated || _refreshToken == null) return;

    final response = await http.post(
      Uri.parse(spotifyTokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken!,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _storeTokens(data);
    } else {
      throw Exception('Token refresh failed');
    }
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'] as String;
    _refreshToken = data['refresh_token'] as String? ?? _refreshToken;
    final expiresIn = data['expires_in'] as int? ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    await _storage.write(key: 'spotify_access_token', value: _accessToken);
    await _storage.write(key: 'spotify_refresh_token', value: _refreshToken);
    await _storage.write(
      key: 'spotify_expires_at',
      value: _expiresAt!.millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    await _storage.delete(key: 'spotify_access_token');
    await _storage.delete(key: 'spotify_refresh_token');
    await _storage.delete(key: 'spotify_expires_at');
  }
}
