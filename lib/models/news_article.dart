class NewsArticle {
  final String title, description, url, source;
  const NewsArticle({
    required this.title, required this.description,
    required this.url, required this.source,
  });
}

class WeatherModel {
  final double temp, feelsLike, windspeed;
  final int code;
  final List<Map<String, dynamic>> daily;
  const WeatherModel({
    required this.temp, required this.feelsLike, required this.windspeed,
    required this.code, required this.daily,
  });
  bool get isRaining => code >= 51 && code <= 99;
  bool get isSnowing => code >= 71 && code <= 77;
  bool get isCloudy  => code >= 2 && code < 51;
  String get emoji {
    if (isRaining) return '🌧️';
    if (isSnowing) return '❄️';
    if (isCloudy)  return '⛅';
    if (code == 0) return '☀️';
    return '🌤️';
  }
  String get description {
    if (isRaining) return 'ممطر';
    if (isSnowing) return 'ثلجي';
    if (isCloudy)  return 'غائم';
    if (code == 0) return 'صافٍ';
    return 'غيوم خفيفة';
  }
  factory WeatherModel.fromJson(Map<String, dynamic> j) {
    final cur  = j['current_weather'] as Map<String, dynamic>;
    final d    = j['daily'] as Map<String, dynamic>?;
    final code = (cur['weathercode'] as num).toInt();
    final temp = (cur['temperature'] as num).toDouble();
    final wind = (cur['windspeed']   as num).toDouble();
    final List<Map<String, dynamic>> dl = [];
    if (d != null) {
      final ts = d['time'] as List;
      final mx = d['temperature_2m_max'] as List;
      final mn = d['temperature_2m_min'] as List;
      for (int i = 0; i < ts.length && i < 7; i++) {
        dl.add({'date': ts[i], 'max': (mx[i] as num).toDouble(), 'min': (mn[i] as num).toDouble()});
      }
    }
    return WeatherModel(
      temp: temp, feelsLike: temp - 2, windspeed: wind, code: code, daily: dl,
    );
  }
}

class PrayerModel {
  final Map<String, String> times;
  final String city;
  PrayerModel({required this.times, required this.city});
  static const _names = {
    'Fajr': 'الفجر', 'Sunrise': 'الشروق', 'Dhuhr': 'الظهر',
    'Asr': 'العصر', 'Maghrib': 'المغرب', 'Isha': 'العشاء',
  };
  static const _icons = {
    'الفجر': '🌙', 'الشروق': '🌅', 'الظهر': '☀️',
    'العصر': '🌤️', 'المغرب': '🌆', 'العشاء': '⭐',
  };
  List<Map<String, dynamic>> get prayerList => _names.entries
      .map((e) => {'name': e.value, 'icon': _icons[e.value] ?? '🕌', 'time': times[e.key] ?? ''})
      .toList();
  Map<String, dynamic>? get nextPrayer {
    final now = DateTime.now();
    for (final pr in prayerList) {
      if (pr['name'] == 'الشروق') continue;
      final parts = (pr['time'] as String).split(':');
      if (parts.length < 2) continue;
      final dt = DateTime(now.year, now.month, now.day,
          int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
      if (dt.isAfter(now)) return {...pr, 'dt': dt};
    }
    return null;
  }
  factory PrayerModel.fromJson(Map<String, dynamic> j, String city) {
    final t = j['data']['timings'] as Map<String, dynamic>;
    return PrayerModel(city: city, times: {
      'Fajr': (t['Fajr'] ?? '').toString().split(' ').first,
      'Sunrise': (t['Sunrise'] ?? '').toString().split(' ').first,
      'Dhuhr': (t['Dhuhr'] ?? '').toString().split(' ').first,
      'Asr': (t['Asr'] ?? '').toString().split(' ').first,
      'Maghrib': (t['Maghrib'] ?? '').toString().split(' ').first,
      'Isha': (t['Isha'] ?? '').toString().split(' ').first,
    });
  }
}

class CurrencyModel {
  final Map<String, double> rates;
  CurrencyModel({required this.rates});
  static const supported = {
    'USD': ('🇺🇸', 'دولار'),
    'EUR': ('🇪🇺', 'يورو'),
    'GBP': ('🇬🇧', 'جنيه'),
    'SAR': ('🇸🇦', 'ريال'),
    'AED': ('🇦🇪', 'درهم'),
    'DZD': ('🇩🇿', 'د.ج'),
    'MAD': ('🇲🇦', 'درهم م'),
    'LYD': ('🇱🇾', 'د.ل'),
    'EGP': ('🇪🇬', 'جنيه م'),
  };
  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    if (from == 'TND') return amount * (rates[to] ?? 1);
    if (to == 'TND')   return amount / (rates[from] ?? 1);
    return amount / (rates[from] ?? 1) * (rates[to] ?? 1);
  }
  factory CurrencyModel.fromJson(Map<String, dynamic> j) {
    final tnd = j['tnd'] as Map<String, dynamic>? ?? {};
    final Map<String, double> r = {};
    for (final k in tnd.keys) {
      final v = tnd[k];
      if (v != null) r[k.toUpperCase()] = (v as num).toDouble();
    }
    return CurrencyModel(rates: r);
  }
}

class TriviaQuestion {
  final String question, correct;
  final List<String> options;
  const TriviaQuestion({required this.question, required this.correct, required this.options});
  factory TriviaQuestion.fromJson(Map<String, dynamic> j) {
    final opts = [
      ...(j['incorrect_answers'] as List).map((e) => _decode(e.toString())),
      _decode(j['correct_answer'].toString()),
    ]..shuffle();
    return TriviaQuestion(
      question: _decode(j['question'] as String),
      correct: _decode(j['correct_answer'].toString()),
      options: opts,
    );
  }
  static String _decode(String s) => s
    .replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"').replaceAll('&#039;', "'").replaceAll('&eacute;', 'é')
    .replaceAll('&egrave;', 'è').replaceAll('&agrave;', 'à').replaceAll('&uuml;', 'ü')
    .replaceAll('&ouml;', 'ö').replaceAll('&auml;', 'ä').replaceAll('&ntilde;', 'ñ')
    .replaceAll('&oacute;', 'ó').replaceAll('&aacute;', 'á').replaceAll('&iacute;', 'í')
    .replaceAll('&uacute;', 'ú').replaceAll('&ccedil;', 'ç').replaceAll('&hellip;', '…')
    .replaceAll('&laquo;', '«').replaceAll('&raquo;', '»').replaceAll('&ndash;', '–')
    .replaceAll('&mdash;', '—').replaceAll('&rsquo;', "'").replaceAll('&lsquo;', "'")
    .replaceAll('&ldquo;', '"').replaceAll('&rdquo;', '"');
}
