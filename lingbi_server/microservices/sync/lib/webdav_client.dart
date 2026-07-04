import 'dart:io';
import 'package:http/http.dart' as http;

class WebDAVClient {
  String baseUrl;
  String username;
  String password;
  final Map<String, String> _headers = {};

  WebDAVClient({
    required this.baseUrl,
    required this.username,
    required this.password,
  }) {
    _headers['Authorization'] = 'Basic ${_encodeCredentials()}';
    _headers['Depth'] = '1';
  }

  String _encodeCredentials() {
    final credentials = '$username:$password';
    return base64Encode(utf8.encode(credentials));
  }

  Future<List<Map<String, dynamic>>> listFiles(String remotePath) async {
    try {
      final uri = Uri.parse('$baseUrl$remotePath');
      final response = await http.request(
        'PROPFIND',
        uri,
        headers: _headers,
        body: '<propfind xmlns="DAV:"><prop><getcontentlength/><getlastmodified/></prop></propfind>',
      );

      if (response.statusCode == 207) {
        // Parse WebDAV response (simplified - in production use a proper XML parser)
        return [];
      } else {
        throw Exception('Failed to list files: ${response.statusCode}');
      }
    } catch (e) {
      print('WebDAV listFiles error: $e');
      rethrow;
    }
  }

  Future<void> uploadFile(String remotePath, Uint8List data) async {
    try {
      final uri = Uri.parse('$baseUrl$remotePath');
      final response = await http.put(
        uri,
        headers: _headers,
        body: data,
      );

      if (response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('WebDAV uploadFile error: $e');
      rethrow;
    }
  }

  Future<Uint8List> downloadFile(String remotePath) async {
    try {
      final uri = Uri.parse('$baseUrl$remotePath');
      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      return Uint8List.fromList(response.bodyBytes);
    } catch (e) {
      print('WebDAV downloadFile error: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String remotePath) async {
    try {
      final uri = Uri.parse('$baseUrl$remotePath');
      final response = await http.delete(
        uri,
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      print('WebDAV deleteFile error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFileInfo(String remotePath) async {
    try {
      final uri = Uri.parse('$baseUrl$remotePath');
      final response = await http.request(
        'PROPFIND',
        uri,
        headers: {..._headers, 'Depth': '0'},
        body: '<propfind xmlns="DAV:"><prop><getcontentlength/><getlastmodified/><getetag/></prop></propfind>',
      );

      if (response.statusCode == 207) {
        // Parse response
        return {
          'path': remotePath,
          'etag': response.headers['etag'],
        };
      } else {
        throw Exception('Failed to get file info: ${response.statusCode}');
      }
    } catch (e) {
      print('WebDAV getFileInfo error: $e');
      rethrow;
    }
  }
}