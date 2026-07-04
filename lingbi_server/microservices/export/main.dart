import 'dart:convert';
import 'dart:io';
import 'package:export/export_service.dart';
import 'package:export/pandoc_converter.dart';

void main() async {
  final exportService = ExportService();
  final converter = PandocConverter();
  
  HttpServer server;
  try {
    server = await HttpServer.bind('0.0.0.0', 8085);
    print('Export Service listening on port 8085');
    
    server.listen((HttpRequest request) async {
      try {
        if (request.uri.path == '/health' && request.method == 'GET') {
          request.response.statusCode = 200;
          request.response.write(jsonEncode({'status': 'healthy'}));
          await request.response.close();
          return;
        }
        
        if (request.uri.path == '/formats' && request.method == 'GET') {
          request.response.statusCode = 200;
          request.response.write(jsonEncode(converter.supportedFormats));
          await request.response.close();
          return;
        }
        
        if (request.uri.path == '/export' && request.method == 'POST') {
          final body = await request.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          
          final format = data['format'] as String? ?? 'markdown';
          final content = data['content'] as String? ?? '';
          final title = data['title'] as String? ?? 'untitled';
          
          final result = await exportService.export(content, title, format);
          
          request.response.statusCode = 200;
          request.response.write(jsonEncode(result));
          await request.response.close();
          return;
        }
        
        request.response.statusCode = 404;
        request.response.write(jsonEncode({'error': 'Not found'}));
        await request.response.close();
      } catch (e) {
        request.response.statusCode = 500;
        request.response.write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      }
    });
  } catch (e) {
    print('Failed to start Export Service: $e');
  }
}