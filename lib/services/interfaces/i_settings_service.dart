import 'package:flutter/material.dart';

/// 设置服务接口
abstract class ISettingsService implements ChangeNotifier {
  ThemeMode get themeMode;
  Locale get locale;
  String get localeName;
  void setLocale(String localeCode);
  String get selectedProvider;
  bool get isInitialized;

  String getApiKey(String provider);
  String getApiUrl(String provider);
  Future<void> initialize();
  void setThemeMode(ThemeMode mode);
  void setProvider(String name);
  void setApiKey(String provider, String key);
  void setApiUrl(String provider, String url);
}
