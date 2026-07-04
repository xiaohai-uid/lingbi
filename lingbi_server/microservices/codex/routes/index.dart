import 'package:dart_frog/dart_frog.dart';
import 'package:codex/lib/codex_store.dart';

RequestHandler handler(Request request) async {
  final method = request.method;

  // Route matching
  if (request.uri.path == '/') {
    if (method == 'GET') {
      return _handleList(request);
    } else if (method == 'POST') {
      return _handleCreate(request);
    }
  } else if (request.uri.path == '/search') {
    if (method == 'POST') {
      return _handleSearch(request);
    }
  } else if (request.uri.pathSegments.length == 2) {
    final id = request.uri.pathSegments[1];
    
    if (method == 'GET') {
      return _handleGetById(id);
    } else if (method == 'PUT') {
      return _handleUpdate(request, id);
    } else if (method == 'DELETE') {
      return _handleDelete(id);
    }
  } else if (request.uri.path == '/health') {
    return _handleHealth();
  }

  return Response(statusCode: 404, body: 'Not Found');
}

Response _handleHealth() {
  return Response(
    body: jsonEncode({
      'status': 'healthy',
      'service': 'codex',
      'version': '1.0.0',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

Response _handleList(Request request) {
  final type = request.uri.queryParameters['type'];
  final entries = codexStore.list(type: type);
  
  return Response(
    body: jsonEncode({
      'data': entries,
      'count': entries.length,
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

Response _handleGetById(String id) {
  final entry = codexStore.getById(id);
  
  if (entry == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Entry not found'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  return Response(
    body: jsonEncode({'data': entry}),
    headers: {'Content-Type': 'application/json'},
  );
}

Future<Response> _handleCreate(Request request) async {
  try {
    final body = await request.jsonDecode();
    
    if (!body.containsKey('type') || !body.containsKey('name')) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Missing required fields: type, name'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    
    final type = body['type'];
    final name = body['name'];
    final description = body['description'];
    final tags = body['tags'] != null ? List<String>.from(body['tags']) : null;
    final metadata = body['metadata'];
    
    final entry = await codexStore.create(
      type: type,
      name: name,
      description: description,
      tags: tags,
      metadata: metadata,
    );
    
    return Response(
      statusCode: 201,
      body: jsonEncode({'data': entry}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<Response> _handleUpdate(Request request, String id) async {
  try {
    final body = await request.jsonDecode();
    
    final name = body['name'];
    final description = body['description'];
    final tags = body['tags'] != null ? List<String>.from(body['tags']) : null;
    final metadata = body['metadata'];
    
    final entry = await codexStore.update(
      id: id,
      name: name,
      description: description,
      tags: tags,
      metadata: metadata,
    );
    
    if (entry == null) {
      return Response(
        statusCode: 404,
        body: jsonEncode({'error': 'Entry not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    
    return Response(
      body: jsonEncode({'data': entry}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<Response> _handleDelete(String id) async {
  final deleted = await codexStore.delete(id);
  
  if (!deleted) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Entry not found'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  return Response(
    statusCode: 204,
  );
}

Future<Response> _handleSearch(Request request) async {
  try {
    final body = await request.jsonDecode();
    
    if (!body.containsKey('query')) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Missing required field: query'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    
    final queryText = body['query'];
    final limit = body['limit'] ?? 5;
    final type = body['type'];
    
    // TODO: Implement text-to-vector embedding
    // For now, we'll simulate by searching entries with the query text in name/description
    // In production, you would call an embedding service to convert queryText to vector
    // and then use semantic search
    
    // Simple fallback search without vector
    final entries = await codexStore.list(type: type);
    
    // Filter entries containing the query text
    final matches = entries.where((entry) {
      final name = (entry['name'] ?? '').toLowerCase();
      final description = (entry['description'] ?? '').toLowerCase();
      final searchText = queryText.toLowerCase();
      return name.contains(searchText) || description.contains(searchText);
    }).toList();
    
    // Add a simulated distance score
    final results = matches.map((entry) => {
      ...entry,
      'distance': 0.0, // Placeholder, real implementation would compute this
    }).toList();
    
    return Response(
      body: jsonEncode({
        'data': results.take(limit).toList(),
        'count': results.length,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
