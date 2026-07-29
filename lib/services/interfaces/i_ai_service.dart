import 'package:lingbi/shared/ai/ai_provider.dart';

/// AI 服务接口
abstract class IAIService {
  String get currentProviderName;
  List<AIProvider> get availableProviders;

  void setProvider(String name);
  void setProjectContext(String context);
  void configureApiKey(String provider, String key);

  Stream<String> chat({
    required String message,
    double temperature = 0.7,
    int maxTokens = 2048,
  });

  Future<String> analyzeStyle(String text);
  Future<String> analyzeNovel(String text);
  Stream<String> continueWriting(String text);
}
