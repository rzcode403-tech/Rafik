import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_config.dart';
import '../models/news_article.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

const String kBackendBase  = 'https://rzcode.tn/application';
const String kConfigApi    = '$kBackendBase/api/config.php';
const String kActivateApi  = '$kBackendBase/api/activation.php';
const String kDeviceIdKey  = 'device_id';
const String kActCodeKey   = 'act_code';
const String kActExpiryKey = 'act_expiry';
const String kActCheckedAt = 'act_checked_at'; // وقت آخر تحقق ناجح

// ── Config ───────────────────────────────────────────────────
class ConfigService {
  static Future<bool> fetchAndApply() async {
    try {
      final res = await http.get(Uri.parse(kConfigApi))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (j['status'] == 'ok' || j['success'] == true) {
          AppConfig.applyFromJson(j);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}

// ── Activation ───────────────────────────────────────────────
enum ActivationStatus { valid, expired, invalidCode, wrongDevice, networkError, notActivated }

class ActivationResult {
  final ActivationStatus status;
  final String? message;
  final int? daysLeft;
  const ActivationResult({required this.status, this.message, this.daysLeft});
}

class ActivationService {
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(kDeviceIdKey);
    if (id != null && id.isNotEmpty) return id;
    id = 'RAFIQ_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4,'0')}';
    await prefs.setString(kDeviceIdKey, id);
    return id;
  }

  /// تحقق من حالة التفعيل — دائماً من الخادم
  static Future<ActivationResult> checkStatus() async {
    final prefs    = await SharedPreferences.getInstance();
    final code     = prefs.getString(kActCodeKey);
    final expiry   = prefs.getString(kActExpiryKey);
    final deviceId = await getDeviceId();

    if (code == null || code.isEmpty) {
      return const ActivationResult(status: ActivationStatus.notActivated);
    }

    // محاولة التحقق من الخادم بـ action=check
    try {
      final res = await http.post(
        Uri.parse(kActivateApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'check', 'code': code, 'device_id': deviceId}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes).trim();
        // إذا الـ API لا يدعم action=check يرجع HTML أو خطأ
        if (!body.startsWith('{')) {
          // fallback: جرّب action=verify
          return await _verifyFallback(code, deviceId, prefs, expiry);
        }
        final j = jsonDecode(body) as Map<String, dynamic>;

        // نجح التحقق
        if (j['success'] == true || j['valid'] == true) {
          await prefs.setString(kActCheckedAt, DateTime.now().toIso8601String());
          return ActivationResult(
            status: ActivationStatus.valid,
            daysLeft: j['days_left'],
          );
        }

        // الكود ملغى أو محذوف → امسح المحلي فوراً
        await _clearLocal(prefs);
        final err = (j['error'] ?? j['message'] ?? '').toString();
        if (err.contains('expired'))      return ActivationResult(status: ActivationStatus.expired,     message: j['message']?.toString());
        if (err.contains('wrong_device')) return ActivationResult(status: ActivationStatus.wrongDevice, message: j['message']?.toString());
        return ActivationResult(status: ActivationStatus.invalidCode, message: j['message']?.toString());
      }
    } catch (_) {}

    // لا إنترنت → grace period: إذا آخر تحقق ناجح منذ أقل من 24 ساعة اسمح
    final checkedAt = prefs.getString(kActCheckedAt);
    if (checkedAt != null && expiry != null) {
      final lastCheck = DateTime.tryParse(checkedAt);
      final expiryDate = DateTime.tryParse(expiry);
      final now = DateTime.now();
      if (lastCheck != null && now.difference(lastCheck).inHours < 24) {
        if (expiryDate != null && now.isBefore(expiryDate)) {
          return ActivationResult(
            status: ActivationStatus.valid,
            daysLeft: expiryDate.difference(now).inDays,
            message: 'وضع بدون إنترنت',
          );
        }
      }
    }

    return const ActivationResult(status: ActivationStatus.notActivated);
  }

  /// fallback إذا activation.php لا يدعم action=check — يجرّب action=verify
  static Future<ActivationResult> _verifyFallback(
      String code, String deviceId, SharedPreferences prefs, String? expiry) async {
    try {
      final res = await http.post(
        Uri.parse(kActivateApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'verify', 'code': code, 'device_id': deviceId}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes).trim();
        if (body.startsWith('{')) {
          final j = jsonDecode(body) as Map<String, dynamic>;
          if (j['success'] == true || j['valid'] == true) {
            await prefs.setString(kActCheckedAt, DateTime.now().toIso8601String());
            return ActivationResult(status: ActivationStatus.valid, daysLeft: j['days_left']);
          }
          await _clearLocal(prefs);
          return ActivationResult(status: ActivationStatus.invalidCode, message: j['message']?.toString());
        }
      }
    } catch (_) {}

    // كلا الـ endpoints فشلا → استخدم expiry المحلي
    if (expiry != null) {
      final d = DateTime.tryParse(expiry);
      if (d != null && DateTime.now().isBefore(d)) {
        return ActivationResult(
          status: ActivationStatus.valid,
          daysLeft: d.difference(DateTime.now()).inDays,
        );
      }
    }
    return const ActivationResult(status: ActivationStatus.notActivated);
  }

  static Future<ActivationResult> activate(String code) async {
    try {
      final deviceId = await getDeviceId();
      final res = await http.post(
        Uri.parse(kActivateApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'activate', 'code': code.trim().toUpperCase(), 'device_id': deviceId}),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200)
        return const ActivationResult(status: ActivationStatus.networkError);

      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (j['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kActCodeKey,   code.trim().toUpperCase());
        await prefs.setString(kActExpiryKey, j['expires_at']?.toString() ?? '');
        await prefs.setString(kActCheckedAt, DateTime.now().toIso8601String());
        return ActivationResult(
          status: ActivationStatus.valid,
          message: j['message']?.toString(),
          daysLeft: j['days_left'],
        );
      }
      final err = (j['error'] ?? '').toString();
      if (err == 'wrong_device') return ActivationResult(status: ActivationStatus.wrongDevice, message: j['message']?.toString());
      if (err == 'expired')      return ActivationResult(status: ActivationStatus.expired,     message: j['message']?.toString());
      return ActivationResult(status: ActivationStatus.invalidCode, message: j['message']?.toString());
    } catch (_) {
      return const ActivationResult(status: ActivationStatus.networkError, message: 'تحقق من الاتصال بالإنترنت');
    }
  }

  static Future<void> _clearLocal(SharedPreferences prefs) async {
    await prefs.remove(kActCodeKey);
    await prefs.remove(kActExpiryKey);
    await prefs.remove(kActCheckedAt);
  }
}

// ── Weather ──────────────────────────────────────────────────
class WeatherService {
  static Future<WeatherModel?> fetch(double lat, double lon) async {
    final url = 'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon&current_weather=true'
        '&daily=temperature_2m_max,temperature_2m_min,weathercode'
        '&timezone=Africa%2FTunis&forecast_days=7';
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200)
        return WeatherModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (_) {}
    return null;
  }
}

// ── Prayer ───────────────────────────────────────────────────
class PrayerService {
  static Future<PrayerModel?> fetch(String city) async {
    final now = DateTime.now();
    final url = 'https://api.aladhan.com/v1/timingsByCity'
        '?city=${Uri.encodeComponent(city)}&country=TN&method=3'
        '&date=${now.day}-${now.month}-${now.year}';
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200)
        return PrayerModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)), city);
    } catch (_) {}
    return null;
  }
}

// ── Currency ─────────────────────────────────────────────────
class CurrencyService {
  static Future<CurrencyModel?> fetch() async {
    final urls = AppConfig.apiUrls('currency').isNotEmpty
        ? AppConfig.apiUrls('currency')
        : [
            'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/tnd.json',
            'https://latest.currency-api.pages.dev/v1/currencies/tnd.json',
          ];
    for (final url in urls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200)
          return CurrencyModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      } catch (_) {}
    }
    return null;
  }
}

// ── News ─────────────────────────────────────────────────────
class NewsService {
  static Future<List<NewsArticle>> fetch() async {
    final feeds = AppConfig.newsFeeds.isNotEmpty
        ? AppConfig.newsFeeds
        : [
            NewsSource(name: 'موزاييك', url: 'https://www.mosaiquefm.net/ar/rss', emoji: '📻', color: '#C8102E', category: 'تونس'),
            NewsSource(name: 'الجزيرة', url: 'https://www.aljazeera.net/ajax/rss/all', emoji: '🌍', color: '#388E3C', category: 'عربي'),
          ];
    final articles = <NewsArticle>[];
    for (final f in feeds) {
      try {
        final res = await http.get(Uri.parse(f.url),
            headers: {'User-Agent': 'Mozilla/5.0 (Android)'})
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200)
          _parseRss(utf8.decode(res.bodyBytes), f.name, articles, 8);
      } catch (_) {}
    }
    articles.shuffle();
    return articles.take(60).toList();
  }

  static Future<List<NewsArticle>> fetchTrending() async {
    final articles = <NewsArticle>[];
    for (final f in AppConfig.trendFeeds) {
      try {
        final res = await http.get(Uri.parse(f.url),
            headers: {'User-Agent': 'Mozilla/5.0 (Android)'})
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200)
          _parseRss(utf8.decode(res.bodyBytes), f.name, articles, 10);
      } catch (_) {}
    }
    return articles;
  }

  static void _parseRss(String body, String src, List<NewsArticle> out, int lim) {
    final items = RegExp(r'<item>(.*?)</item>', dotAll: true).allMatches(body);
    for (final m in items.take(lim)) {
      final item = m.group(1) ?? '';
      final t = RegExp(r'<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>',   dotAll: true).firstMatch(item);
      final d = RegExp(r'<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>', dotAll: true).firstMatch(item);
      final l = RegExp(r'<link>(.*?)</link>').firstMatch(item);
      final title = (t?.group(1) ?? '').trim();
      if (title.isNotEmpty) {
        out.add(NewsArticle(
          title: title,
          description: (d?.group(1) ?? '').replaceAll(RegExp(r'<[^>]+>'), ' ').trim(),
          url: l?.group(1)?.trim() ?? '',
          source: src,
        ));
      }
    }
  }
}

// ── Jokes ─────────────────────────────────────────────────────
class JokeService {
  static (String, String) getLocal() {
    final j = AppConfig.jokes;
    if (j.isNotEmpty) {
      final joke = j[Random().nextInt(j.length)];
      return (joke.setup, joke.punchline);
    }
    return ('كيفاش حالك؟', 'دايماً بخير مع رفيق! 😄');
  }
  static Future<(String, String)?> fetchOnline() async {
    try {
      final res = await http.get(
        Uri.parse('https://v2.jokeapi.dev/joke/Pun,Misc?safe-mode&type=twopart'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['type'] == 'twopart')
          return (j['setup'] as String, j['delivery'] as String);
      }
    } catch (_) {}
    return null;
  }
}

// ── Trivia ────────────────────────────────────────────────────
class TriviaService {
  static Future<List<TriviaQuestion>> fetch({int amount = 10}) async {
    try {
      final res = await http.get(
        Uri.parse('https://opentdb.com/api.php?amount=$amount&type=multiple&difficulty=easy'),
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        return (j['results'] as List)
            .map((e) => TriviaQuestion.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}

// ── Translation ───────────────────────────────────────────────
class TranslationService {
  static Future<String?> translate(String text, String from, String to) async {
    try {
      final uri = Uri.parse(
          'https://api.mymemory.translated.net/get'
          '?q=${Uri.encodeComponent(text)}&langpair=$from|$to');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['responseData']['translatedText'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
