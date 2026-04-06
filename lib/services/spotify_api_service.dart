import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyApiService {
  static const String _baseUrl = 'https://api.spotify.com/v1';

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Get current user profile.
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: _headers(token),
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get playlist metadata (name, etc).
  Future<Map<String, dynamic>> getPlaylist(String token, String playlistId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/playlists/$playlistId'),
      headers: _headers(token),
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get all tracks from a playlist, handling pagination.
  Future<List<Map<String, dynamic>>> getPlaylistTracks(
    String token,
    String playlistId,
  ) async {
    final tracks = <Map<String, dynamic>>[];
    int offset = 0;
    const int limit = 100;

    while (true) {
      final response = await http.get(
        Uri.parse('$_baseUrl/playlists/$playlistId/tracks')
            .replace(queryParameters: {'offset': '$offset', 'limit': '$limit'}),
        headers: _headers(token),
      );
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      if (items.isEmpty) break;

      for (final item in items) {
        final track = item['track'];
        if (track != null) {
          tracks.add({
            'title': track['name'] as String,
            'artist': (track['artists'] as List).isNotEmpty
                ? track['artists'][0]['name'] as String
                : 'Unknown',
          });
        }
      }

      if (data['next'] == null) break;
      offset += limit;
    }

    return tracks;
  }

  /// Get all playlists for the current user.
  Future<List<Map<String, dynamic>>> getUserPlaylists(String token) async {
    final playlists = <Map<String, dynamic>>[];
    String? url = '$_baseUrl/me/playlists?limit=50';

    while (url != null) {
      final response = await http.get(Uri.parse(url), headers: _headers(token));
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      for (final pl in data['items'] as List<dynamic>) {
        playlists.add({
          'id': pl['id'],
          'name': pl['name'],
          'url': 'https://open.spotify.com/playlist/${pl['id']}',
          'track_count': pl['tracks']?['total'] ?? 0,
        });
      }
      url = data['next'] as String?;
    }

    return playlists;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('TOKEN_EXPIRED');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Spotify API error (${response.statusCode}): ${response.body}');
    }
  }
}
