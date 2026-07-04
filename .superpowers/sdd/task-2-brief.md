### Task 2: 创建 AI Provider 微服务（LiteLLM 集成）

**Files:**
- Create: `lingbi_server/microservices/ai_provider/main.dart`
- Create: `lingbi_server/microservices/ai_provider/lib/litellm_client.dart`
- Create: `lingbi_server/microservices/ai_provider/lib/model_config.dart`
- Create: `lingbi_server/microservices/ai_provider/pubspec.yaml`

**Interfaces:**
- Consumes: model_config 配置文件
- Produces: POST /chat (流式), POST /style/analyze, POST /novel/analyze, POST /continue, POST /embedding

- [ ] **Step 1: 创建 LiteLLM 客户端**

```dart
// lib/litellm_client.dart
class LiteLLMClient {
  final HttpClient _client;
  final String baseUrl;
  final Map<String, String> _headers;
  
  LiteLLMClient({required this.baseUrl, Map<String, String> headers = const {}})
    : _client = HttpClient(),
      _headers = {'Content-Type': 'application/json', ...headers};
  
  Future<Stream<String>> chat({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/chat/completions');
    final request = await _client.postUrl(uri);
    
    _headers.forEach(request.headers.set);
    
    final body = {
      'model': model,
      'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    };
    
    await request.add(utf8.encode(jsonEncode(body)));
    
    final response = await request.close();
    final stream = response.cast<List<int>>();
    
    // 解析 SSE 流
    final buffer = StringBuffer();
    return stream.asyncMap((chunk) async {
      buffer.write(utf8.decode(chunk));
      final parts = buffer.toString().split('\n');
      final events = <String>[];
      
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.startsWith('data: ')) {
          final data = part.substring(6);
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            if (json['choices'] != null && json['choices'].isNotEmpty) {
              final content = json['choices'][0]['delta']['content'];
              if (content != null) events.add(content);
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
      
      buffer.clear();
      return events.join('');
    });
  }
}
```

- [ ] **Step 2: 创建模型配置管理**

```dart
// lib/model_config.dart
class ModelConfig {
  final String id;
  final String name;
  final String type; // openai_compatible, deepseek, claude, qwen, zhipu, etc.
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool enabled;
  final Map<String, dynamic> config;
  
  const ModelConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.enabled = true,
    this.config = const {},
  });
  
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      baseUrl: json['baseUrl'] ?? '',
      apiKey: json['apiKey'] ?? '',
      model: json['model'],
      enabled: json['enabled'] ?? true,
      config: json['config'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'enabled': enabled,
      'config': config,
    };
  }
  
  String get headers => {
    'Content-Type': 'application/json',
    if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
  };
}

class ModelConfigService {
  final List<ModelConfig> _models = [];
  
  Future<void> loadConfigs(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    
    final content = await file.readAsString();
    final json = jsonDecode(content) as List;
    _models.clear();
    _models.addAll(json.map((m) => ModelConfig.fromJson(m)));
  }
  
  Future<void> saveConfigs(String filePath) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(_models.map((m) => m.toJson()).toList()));
  }
  
  ModelConfig? getModel(String id) => _models.firstWhere((m) => m.id == id, orElse: () => _models.first);
  List<ModelConfig> listModels() => _models;
  Future<void> addModel(ModelConfig model) async => _models.add(model);
  Future<void> removeModel(String id) async => _models.removeWhere((m) => m.id == id);
}
```

- [ ] **Step 3: 创建 AI 微服务路由**

```dart
// main.dart
void main() async {
  await _startServer();
}

Future<void> _startServer() async {
  final configService = ModelConfigService();
  await configService.loadConfigs('.models.json');
  
  final server = Server(
    port: 8081,
    routes: [
      Post('/chat', (ctx) => _handleChat(ctx, configService)),
      Post('/style/analyze', (ctx) => _handleStyleAnalyze(ctx, configService)),
      Post('/novel/analyze', (ctx) => _handleNovelAnalyze(ctx, configService)),
      Post('/continue', (ctx) => _handleContinue(ctx, configService)),
      Post('/embedding', (ctx) => _handleEmbedding(ctx, configService)),
      Get('/models', (ctx) async => Response(body: jsonEncode(configService.listModels()))),
      Post('/models', (ctx) async {
        final model = ModelConfig.fromJson(await ctx.request.json);
        await configService.addModel(model);
        await configService.saveConfigs('.models.json');
        return Response(statusCode: 201, body: jsonEncode(model));
      }),
    ],
  );
  
  await server.start();
}
```

- [ ] **Step 4: 测试 LiteLLM 连接**

```bash
# 测试 Ollama 连接
curl -X POST http://localhost:8081/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:7b","messages":[{"role":"user","content":"你好"}],"stream":true}'
```

- [ ] **Step 5: Commit**

```bash
git add lingbi_server/microservices/ai_provider/
git commit -m "feat: create AI Provider microservice with LiteLLM integration"
```

---

