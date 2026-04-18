import 'dart:convert';
import 'package:http/http.dart' as http;

/// Generic HTTP client wrapper with error handling.
class ApiService {
  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// GET request with optional headers.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET request returning a list.
  Future<List<dynamic>> getList(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw ApiException(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Handle HTTP response.
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } else {
      throw ApiException(
        'API Error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
