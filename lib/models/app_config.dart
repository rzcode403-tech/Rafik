import 'package:flutter/material.dart';

class AppConfig {
  static String appName     = 'رفيق';
  static String appSubtitle = 'مساعدك الذكي التونسي';
  static String splashEmoji = '🤝';
  static Color  colorPrimary = const Color(0xFFC8102E);
  static Color  colorAccent  = const Color(0xFFD4AF37);
  static Color  colorDarkBg  = const Color(0xFF0D1117);
  static bool   activationRequired = true;
  static int    trialDays    = 3;
  static String appVersion   = '2.0.0';

  static List<AppSection>            sections   = [];
  static Map<String, List<ApiEntry>> apis       = {};
  static List<NewsSource>   newsFeeds  = [];
  static List<NewsSource>   trendFeeds = [];
  static List<TVChannel>    tvChannels = [];
  static List<RadioStation> radios     = [];
  static List<AppJoke>      jokes      = [];
  static List<AppGame>      games      = [];
  static List<AppCity>      cities     = [];

  static void applyFromJson(Map<String, dynamic> json) {
    final s = (json['settings'] as Map<String, dynamic>?) ?? {};
    appName     = s['app_name']     ?? appName;
    appSubtitle = s['app_subtitle'] ?? appSubtitle;
    splashEmoji = s['splash_emoji'] ?? splashEmoji;
    appVersion  = s['app_version']  ?? appVersion;
    colorPrimary = _hex(s['color_primary'], colorPrimary);
    colorAccent  = _hex(s['color_accent'],  colorAccent);
    colorDarkBg  = _hex(s['color_dark_bg'], colorDarkBg);
    // ⚠️ إصلاح ثغرة التفعيل: activationRequired يُقرأ فقط من الخادم
    // لا يمكن إيقافه محلياً — القيمة الافتراضية true
    final serverVal = s['activation_required'];
    activationRequired = serverVal == null ? true : (serverVal == true || serverVal == 1);
    trialDays = (s['trial_days'] as num?)?.toInt() ?? trialDays;

    sections   = _list(json['sections'],    AppSection.fromJson);
    newsFeeds  = _list(json['news_feeds'],  NewsSource.fromJson);
    trendFeeds = _list(json['trend_feeds'], NewsSource.fromJson);
    tvChannels = _list(json['tv_channels'], TVChannel.fromJson);
    radios     = _list(json['radios'],      RadioStation.fromJson);
    jokes      = _list(json['jokes'],       AppJoke.fromJson);
    games      = _list(json['games'],       AppGame.fromJson);
    cities     = _list(json['cities'],      AppCity.fromJson);

    final apiMap = json['apis'] as Map<String, dynamic>? ?? {};
    apis = apiMap.map((k, v) => MapEntry(k, _list(v, ApiEntry.fromJson)));
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) fn) {
    if (raw == null) return [];
    return (raw as List).map((e) => fn(e as Map<String, dynamic>)).toList();
  }

  static Color _hex(dynamic val, Color fallback) {
    if (val == null) return fallback;
    try {
      final hex = val.toString().replaceAll('#', '').padLeft(6, '0');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) { return fallback; }
  }

  static String apiUrl(String section) =>
      apis[section]?.firstOrNull?.url ?? '';
  static List<String> apiUrls(String section) =>
      apis[section]?.map((e) => e.url).toList() ?? [];
}

// ── AppSection ──────────────────────────────────────────────
class AppSection {
  final String key, nameAr, icon, color, description, navIcon;
  final bool isPremium, navBar;
  const AppSection({
    required this.key, required this.nameAr, required this.icon,
    required this.color, required this.description, required this.navIcon,
    required this.isPremium, required this.navBar,
  });
  Color get colorObj {
    try { return Color(int.parse('FF${color.replaceAll('#', '').padLeft(6,'0')}', radix: 16)); }
    catch (_) { return AppConfig.colorPrimary; }
  }

  // مساعد: يقبل "1", 1, true, "true" كـ true
  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }

  factory AppSection.fromJson(Map<String, dynamic> j) => AppSection(
    key: j['key'] ?? '', nameAr: j['name_ar'] ?? '', icon: j['icon'] ?? '⭐',
    color: j['color'] ?? '#C8102E', description: j['description'] ?? '',
    navIcon: j['nav_icon'] ?? j['icon'] ?? '⭐',
    isPremium: _parseBool(j['is_premium']),
    navBar: _parseBool(j['nav_bar']),
  );
}

// ── ApiEntry ─────────────────────────────────────────────────
class ApiEntry {
  final String name, url;
  final String? fallbackUrl;
  const ApiEntry({required this.name, required this.url, this.fallbackUrl});
  factory ApiEntry.fromJson(Map<String, dynamic> j) =>
      ApiEntry(name: j['name'] ?? '', url: j['url'] ?? '', fallbackUrl: j['fallback_url']);
}

// ── NewsSource ───────────────────────────────────────────────
class NewsSource {
  final String name, url, emoji, color, category;
  const NewsSource({required this.name, required this.url,
      required this.emoji, required this.color, required this.category});
  factory NewsSource.fromJson(Map<String, dynamic> j) => NewsSource(
    name: j['name'] ?? '', url: j['url'] ?? '',
    emoji: j['logo_emoji'] ?? '📰', color: j['color'] ?? '#388E3C',
    category: j['category'] ?? 'عام',
  );
}

// ── TVChannel ────────────────────────────────────────────────
class TVChannel {
  final String name, flag, category, streamUrl;
  final bool isHd;
  const TVChannel({required this.name, required this.flag,
      required this.category, required this.streamUrl, this.isHd = false});
  factory TVChannel.fromJson(Map<String, dynamic> j) => TVChannel(
    name: j['name'] ?? '', flag: j['flag'] ?? '📺',
    category: j['category'] ?? 'أخرى', streamUrl: j['url'] ?? '',
    isHd: _parseBool(j['is_hd']),
  );
}

// ── RadioStation ─────────────────────────────────────────────
class RadioStation {
  final String name, streamUrl, genre, description, emoji, color;
  const RadioStation({required this.name, required this.streamUrl,
      required this.genre, required this.description,
      required this.emoji, required this.color});
  Color get colorObj {
    try { return Color(int.parse('FF${color.replaceAll('#', '').padLeft(6,'0')}', radix: 16)); }
    catch (_) { return AppConfig.colorPrimary; }
  }
  factory RadioStation.fromJson(Map<String, dynamic> j) => RadioStation(
    name: j['name'] ?? '', streamUrl: j['url'] ?? '',
    genre: j['genre'] ?? '', description: j['desc'] ?? '',
    emoji: j['emoji'] ?? '📻', color: j['color'] ?? '#C8102E',
  );
}

// ── AppJoke ──────────────────────────────────────────────────
class AppJoke {
  final int id;
  final String setup, punchline, category;
  const AppJoke({required this.id, required this.setup,
      required this.punchline, required this.category});
  factory AppJoke.fromJson(Map<String, dynamic> j) => AppJoke(
    id: (j['id'] as num?)?.toInt() ?? 0,
    setup: j['setup'] ?? '', punchline: j['punchline'] ?? '',
    category: j['category'] ?? 'عام',
  );
}

// ── AppGame ──────────────────────────────────────────────────
class AppGame {
  final String key, name, description, icon, color;
  const AppGame({required this.key, required this.name,
      required this.description, required this.icon, required this.color});
  Color get colorObj {
    try { return Color(int.parse('FF${color.replaceAll('#', '').padLeft(6,'0')}', radix: 16)); }
    catch (_) { return AppConfig.colorPrimary; }
  }
  factory AppGame.fromJson(Map<String, dynamic> j) => AppGame(
    key: j['key'] ?? '', name: j['name'] ?? '',
    description: j['description'] ?? '', icon: j['icon'] ?? '🎮',
    color: j['color'] ?? '#4527A0',
  );
}

// ── AppCity ──────────────────────────────────────────────────
class AppCity {
  final String nameEn, nameAr;
  final double lat, lng;
  const AppCity({required this.nameEn, required this.nameAr,
      required this.lat, required this.lng});
  factory AppCity.fromJson(Map<String, dynamic> j) => AppCity(
    nameEn: j['name_en'] ?? '', nameAr: j['name_ar'] ?? '',
    lat: (j['lat'] as num?)?.toDouble() ?? 0,
    lng: (j['lng'] as num?)?.toDouble() ?? 0,
  );
}
