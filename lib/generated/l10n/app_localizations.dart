import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @s0.
  ///
  /// In zh, this message translates to:
  /// **'-\', \'质量分'**
  String get s0;

  /// No description provided for @s1.
  ///
  /// In zh, this message translates to:
  /// **'AI 小说生成'**
  String get s1;

  /// No description provided for @s2.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成结果'**
  String get s2;

  /// No description provided for @s3.
  ///
  /// In zh, this message translates to:
  /// **'AI 输出格式异常，已自动重试'**
  String get s3;

  /// No description provided for @s4.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get s4;

  /// No description provided for @s5.
  ///
  /// In zh, this message translates to:
  /// **'API Key 无效，请在设置中更新'**
  String get s5;

  /// No description provided for @s6.
  ///
  /// In zh, this message translates to:
  /// **'Base URL'**
  String get s6;

  /// No description provided for @s7.
  ///
  /// In zh, this message translates to:
  /// **'Invalid API key'**
  String get s7;

  /// No description provided for @s8.
  ///
  /// In zh, this message translates to:
  /// **'Rate limited'**
  String get s8;

  /// No description provided for @s9.
  ///
  /// In zh, this message translates to:
  /// **'https://api.example.com/v1'**
  String get s9;

  /// No description provided for @s10.
  ///
  /// In zh, this message translates to:
  /// **'sk-...'**
  String get s10;

  /// No description provided for @s11.
  ///
  /// In zh, this message translates to:
  /// **'今日配额已用完'**
  String get s11;

  /// No description provided for @s12.
  ///
  /// In zh, this message translates to:
  /// **'例如：一个修仙少年从废材崛起的故事'**
  String get s12;

  /// No description provided for @s13.
  ///
  /// In zh, this message translates to:
  /// **'例如：主角提前得知反派阴谋，改变了原定计划'**
  String get s13;

  /// No description provided for @s14.
  ///
  /// In zh, this message translates to:
  /// **'例如：我的中转站'**
  String get s14;

  /// No description provided for @s15.
  ///
  /// In zh, this message translates to:
  /// **'例如：星穹之下'**
  String get s15;

  /// No description provided for @s16.
  ///
  /// In zh, this message translates to:
  /// **'供应商名称'**
  String get s16;

  /// No description provided for @s17.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get s17;

  /// No description provided for @s18.
  ///
  /// In zh, this message translates to:
  /// **'保存密钥'**
  String get s18;

  /// No description provided for @s19.
  ///
  /// In zh, this message translates to:
  /// **'全部忽略'**
  String get s19;

  /// No description provided for @s20.
  ///
  /// In zh, this message translates to:
  /// **'关系类型'**
  String get s20;

  /// No description provided for @s21.
  ///
  /// In zh, this message translates to:
  /// **'关系详情'**
  String get s21;

  /// No description provided for @s22.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get s22;

  /// No description provided for @s23.
  ///
  /// In zh, this message translates to:
  /// **'分析'**
  String get s23;

  /// No description provided for @s24.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get s24;

  /// No description provided for @s25.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get s25;

  /// No description provided for @s26.
  ///
  /// In zh, this message translates to:
  /// **'删除节拍'**
  String get s26;

  /// No description provided for @s27.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get s27;

  /// No description provided for @s28.
  ///
  /// In zh, this message translates to:
  /// **'刷新记忆'**
  String get s28;

  /// No description provided for @s29.
  ///
  /// In zh, this message translates to:
  /// **'动机'**
  String get s29;

  /// No description provided for @s30.
  ///
  /// In zh, this message translates to:
  /// **'升级会员（爱发电）'**
  String get s30;

  /// No description provided for @s31.
  ///
  /// In zh, this message translates to:
  /// **'参数配置'**
  String get s31;

  /// No description provided for @s32.
  ///
  /// In zh, this message translates to:
  /// **'发现模型'**
  String get s32;

  /// No description provided for @s33.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get s33;

  /// No description provided for @s34.
  ///
  /// In zh, this message translates to:
  /// **'变更描述'**
  String get s34;

  /// No description provided for @s35.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get s35;

  /// No description provided for @s36.
  ///
  /// In zh, this message translates to:
  /// **'国家'**
  String get s36;

  /// No description provided for @s37.
  ///
  /// In zh, this message translates to:
  /// **'在此输入额外的上下文信息，将追加到 AI 提示中...'**
  String get s37;

  /// No description provided for @s38.
  ///
  /// In zh, this message translates to:
  /// **'基于场景摘要生成章摘要'**
  String get s38;

  /// No description provided for @s39.
  ///
  /// In zh, this message translates to:
  /// **'基于章摘要生成卷摘要'**
  String get s39;

  /// No description provided for @s40.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get s40;

  /// No description provided for @s41.
  ///
  /// In zh, this message translates to:
  /// **'宗门'**
  String get s41;

  /// No description provided for @s42.
  ///
  /// In zh, this message translates to:
  /// **'定位（主角/配角/反派/路人）'**
  String get s42;

  /// No description provided for @s43.
  ///
  /// In zh, this message translates to:
  /// **'实力 (1-100)'**
  String get s43;

  /// No description provided for @s44.
  ///
  /// In zh, this message translates to:
  /// **'家族'**
  String get s44;

  /// No description provided for @s45.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get s45;

  /// No description provided for @s46.
  ///
  /// In zh, this message translates to:
  /// **'强度'**
  String get s46;

  /// No description provided for @s47.
  ///
  /// In zh, this message translates to:
  /// **'当前世界还没有可添加章节的作品卷'**
  String get s47;

  /// No description provided for @s48.
  ///
  /// In zh, this message translates to:
  /// **'忽略'**
  String get s48;

  /// No description provided for @s49.
  ///
  /// In zh, this message translates to:
  /// **'性格'**
  String get s49;

  /// No description provided for @s50.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get s50;

  /// No description provided for @s51.
  ///
  /// In zh, this message translates to:
  /// **'恢复后将覆盖当前文档内容，确定继续？'**
  String get s51;

  /// No description provided for @s52.
  ///
  /// In zh, this message translates to:
  /// **'成功导入 \' + result.length.toString() + \' 个文件'**
  String get s52;

  /// No description provided for @s53.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get s53;

  /// No description provided for @s54.
  ///
  /// In zh, this message translates to:
  /// **'描述你想生成的内容\\n例如：继续写第三章…'**
  String get s54;

  /// No description provided for @s55.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get s55;

  /// No description provided for @s56.
  ///
  /// In zh, this message translates to:
  /// **'搜索角色、地点、传说、规则...'**
  String get s56;

  /// No description provided for @s57.
  ///
  /// In zh, this message translates to:
  /// **'搜索项目…'**
  String get s57;

  /// No description provided for @s58.
  ///
  /// In zh, this message translates to:
  /// **'故事画布'**
  String get s58;

  /// No description provided for @s59.
  ///
  /// In zh, this message translates to:
  /// **'新增事件'**
  String get s59;

  /// No description provided for @s60.
  ///
  /// In zh, this message translates to:
  /// **'新增节拍'**
  String get s60;

  /// No description provided for @s61.
  ///
  /// In zh, this message translates to:
  /// **'新建势力'**
  String get s61;

  /// No description provided for @s62.
  ///
  /// In zh, this message translates to:
  /// **'新建章节'**
  String get s62;

  /// No description provided for @s63.
  ///
  /// In zh, this message translates to:
  /// **'新建角色'**
  String get s63;

  /// No description provided for @s64.
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get s64;

  /// No description provided for @s65.
  ///
  /// In zh, this message translates to:
  /// **'暂无版本历史'**
  String get s65;

  /// No description provided for @s66.
  ///
  /// In zh, this message translates to:
  /// **'暂无节拍，点击右上角 + 新增'**
  String get s66;

  /// No description provided for @s67.
  ///
  /// In zh, this message translates to:
  /// **'暂无角色，请先在「角色」标签页创建'**
  String get s67;

  /// No description provided for @s68.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get s68;

  /// No description provided for @s69.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get s69;

  /// No description provided for @s70.
  ///
  /// In zh, this message translates to:
  /// **'正在导出...'**
  String get s70;

  /// No description provided for @s71.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get s71;

  /// No description provided for @s72.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get s72;

  /// No description provided for @s73.
  ///
  /// In zh, this message translates to:
  /// **'添加关系'**
  String get s73;

  /// No description provided for @s74.
  ///
  /// In zh, this message translates to:
  /// **'添加角色关系'**
  String get s74;

  /// No description provided for @s75.
  ///
  /// In zh, this message translates to:
  /// **'源角色'**
  String get s75;

  /// No description provided for @s76.
  ///
  /// In zh, this message translates to:
  /// **'激活会员'**
  String get s76;

  /// No description provided for @s77.
  ///
  /// In zh, this message translates to:
  /// **'玄幻/仙侠/都市/科幻…'**
  String get s77;

  /// No description provided for @s78.
  ///
  /// In zh, this message translates to:
  /// **'生成小说'**
  String get s78;

  /// No description provided for @s79.
  ///
  /// In zh, this message translates to:
  /// **'生成超时，请重试'**
  String get s79;

  /// No description provided for @s80.
  ///
  /// In zh, this message translates to:
  /// **'目标角色'**
  String get s80;

  /// No description provided for @s81.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get s81;

  /// No description provided for @s82.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get s82;

  /// No description provided for @s83.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get s83;

  /// No description provided for @s84.
  ///
  /// In zh, this message translates to:
  /// **'确认恢复'**
  String get s84;

  /// No description provided for @s85.
  ///
  /// In zh, this message translates to:
  /// **'确认添加'**
  String get s85;

  /// No description provided for @s86.
  ///
  /// In zh, this message translates to:
  /// **'章节'**
  String get s86;

  /// No description provided for @s87.
  ///
  /// In zh, this message translates to:
  /// **'章节标题'**
  String get s87;

  /// No description provided for @s88.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get s88;

  /// No description provided for @s89.
  ///
  /// In zh, this message translates to:
  /// **'组织'**
  String get s89;

  /// No description provided for @s90.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get s90;

  /// No description provided for @s91.
  ///
  /// In zh, this message translates to:
  /// **'编辑节拍'**
  String get s91;

  /// No description provided for @s92.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败，请检查网络后重试'**
  String get s92;

  /// No description provided for @s93.
  ///
  /// In zh, this message translates to:
  /// **'背景故事'**
  String get s93;

  /// No description provided for @s94.
  ///
  /// In zh, this message translates to:
  /// **'蝴蝶效应分析'**
  String get s94;

  /// No description provided for @s95.
  ///
  /// In zh, this message translates to:
  /// **'规则名称'**
  String get s95;

  /// No description provided for @s96.
  ///
  /// In zh, this message translates to:
  /// **'规则描述'**
  String get s96;

  /// No description provided for @s97.
  ///
  /// In zh, this message translates to:
  /// **'角色名称'**
  String get s97;

  /// No description provided for @s98.
  ///
  /// In zh, this message translates to:
  /// **'设为当前'**
  String get s98;

  /// No description provided for @s99.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get s99;

  /// No description provided for @s100.
  ///
  /// In zh, this message translates to:
  /// **'起点爆款/番茄爽文…'**
  String get s100;

  /// No description provided for @s101.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get s101;

  /// No description provided for @s102.
  ///
  /// In zh, this message translates to:
  /// **'输入关键词开始搜索'**
  String get s102;

  /// No description provided for @s103.
  ///
  /// In zh, this message translates to:
  /// **'输入搜索关键词...'**
  String get s103;

  /// No description provided for @s104.
  ///
  /// In zh, this message translates to:
  /// **'输入续写方向（可选）…'**
  String get s104;

  /// No description provided for @s105.
  ///
  /// In zh, this message translates to:
  /// **'适用场景（可选，留空=全局）'**
  String get s105;

  /// No description provided for @s106.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get s106;

  /// No description provided for @s107.
  ///
  /// In zh, this message translates to:
  /// **'选择时间线事件'**
  String get s107;

  /// No description provided for @s108.
  ///
  /// In zh, this message translates to:
  /// **'重新分析'**
  String get s108;

  /// No description provided for @s109.
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get s109;

  /// No description provided for @s110.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get s110;

  /// No description provided for @s111.
  ///
  /// In zh, this message translates to:
  /// **'领地'**
  String get s111;

  /// No description provided for @s112.
  ///
  /// In zh, this message translates to:
  /// **'验证并激活'**
  String get s112;

  /// No description provided for @s113.
  ///
  /// In zh, this message translates to:
  /// **'（无显著角色影响）'**
  String get s113;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
