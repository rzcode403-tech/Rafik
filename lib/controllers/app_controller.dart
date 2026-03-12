import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/app_config.dart';
import '../models/news_article.dart';
import '../services/api_service.dart';

class AppController extends ChangeNotifier {
  bool isDark        = false;
  bool isLoading     = false;
  bool configLoaded  = false;
  bool isActivated   = false;
  bool hasInternet   = true;
  String configError = '';

  String selectedCity   = '';
  String selectedCityAr = '';

  WeatherModel?  weather;
  PrayerModel?   prayer;
  CurrencyModel? currency;
  List<NewsArticle> news = [];

  ActivationResult? activationInfo;
  SharedPreferences? _prefs;

  AppCity get currentCity {
    if (AppConfig.cities.isEmpty)
      return const AppCity(nameEn: 'Tunis', nameAr: 'تونس العاصمة', lat: 36.8065, lng: 10.1815);
    if (selectedCity.isEmpty) return AppConfig.cities.first;
    return AppConfig.cities.firstWhere(
      (c) => c.nameEn == selectedCity, orElse: () => AppConfig.cities.first);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    isDark         = _prefs?.getBool('dark')      ?? false;
    selectedCity   = _prefs?.getString('city')    ?? '';
    selectedCityAr = _prefs?.getString('city_ar') ?? '';

    final con = await Connectivity().checkConnectivity();
    hasInternet = con != ConnectivityResult.none;

    if (hasInternet) {
      final ok = await ConfigService.fetchAndApply();
      if (!ok) configError = 'فشل تحميل الإعدادات';
    }

    // بيانات افتراضية تضمن عمل التطبيق دون config.php
    _applyDefaults();

    if (selectedCity.isEmpty && AppConfig.cities.isNotEmpty) {
      selectedCity   = AppConfig.cities.first.nameEn;
      selectedCityAr = AppConfig.cities.first.nameAr;
    }

    if (!AppConfig.activationRequired) {
      isActivated  = true;
      configLoaded = true;
      notifyListeners();
      await loadAll();
      return;
    }

    // تحقق دائماً من الخادم - لا نثق بالكاش المحلي وحده
    activationInfo = await ActivationService.checkStatus();
    isActivated    = activationInfo?.status == ActivationStatus.valid;
    configLoaded   = true;
    notifyListeners();
    if (isActivated) await loadAll();
  }

  // يُستدعى عند عودة التطبيق للواجهة AppLifecycleState.resumed
  Future<void> recheckActivation() async {
    if (!AppConfig.activationRequired) return;
    if (!hasInternet) return;
    final r        = await ActivationService.checkStatus();
    activationInfo = r;
    final was      = isActivated;
    isActivated    = r.status == ActivationStatus.valid;
    if (was && !isActivated) {
      weather = null; prayer = null; currency = null; news = [];
    }
    notifyListeners();
  }

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final city = currentCity;
    await Future.wait([
      WeatherService.fetch(city.lat, city.lng).then((v) { if (v != null) weather  = v; }),
      PrayerService.fetch(city.nameEn).then((v)          { if (v != null) prayer   = v; }),
      CurrencyService.fetch().then((v)                   { if (v != null) currency = v; }),
      NewsService.fetch().then((v)                       { if (v.isNotEmpty) news  = v; }),
    ]);
    isLoading = false;
    notifyListeners();
  }

  Future<void> doActivate(String code) async {
    final r = await ActivationService.activate(code);
    activationInfo = r;
    isActivated    = r.status == ActivationStatus.valid;
    if (isActivated) await loadAll();
    notifyListeners();
  }

  void toggleDark() {
    isDark = !isDark;
    _prefs?.setBool('dark', isDark);
    notifyListeners();
  }

  void setCity(String en, String ar) {
    selectedCity   = en;
    selectedCityAr = ar;
    _prefs?.setString('city',    en);
    _prefs?.setString('city_ar', ar);
    loadAll();
    notifyListeners();
  }

  void _applyDefaults() {
    if (AppConfig.sections.isEmpty) {
      AppConfig.sections = [
        AppSection(key: 'home',      nameAr: 'الرئيسية',     icon: '🏠', color: '#C8102E', description: '', navIcon: '🏠', isPremium: false, navBar: true),
        AppSection(key: 'weather',   nameAr: 'الطقس',        icon: '🌤️', color: '#1976D2', description: '', navIcon: '🌤️', isPremium: false, navBar: true),
        AppSection(key: 'prayer',    nameAr: 'الصلاة',       icon: '🕌', color: '#388E3C', description: '', navIcon: '🕌', isPremium: false, navBar: true),
        AppSection(key: 'news',      nameAr: 'الأخبار',      icon: '📰', color: '#F57C00', description: '', navIcon: '📰', isPremium: false, navBar: true),
        AppSection(key: 'more',      nameAr: 'المزيد',       icon: '⚡',  color: '#7B1FA2', description: '', navIcon: '⚡', isPremium: false, navBar: true),
        AppSection(key: 'currency',  nameAr: 'العملات',      icon: '💱', color: '#00796B', description: '', navIcon: '💱', isPremium: false, navBar: false),
        AppSection(key: 'translate', nameAr: 'الترجمة',      icon: '🌍', color: '#0097A7', description: '', navIcon: '🌍', isPremium: false, navBar: false),
        AppSection(key: 'jokes',     nameAr: 'نكت',          icon: '😄', color: '#FBC02D', description: '', navIcon: '😄', isPremium: false, navBar: false),
        AppSection(key: 'games',     nameAr: 'الألعاب',      icon: '🎮', color: '#4527A0', description: '', navIcon: '🎮', isPremium: false, navBar: false),
        AppSection(key: 'trending',  nameAr: 'الترند',       icon: '🔥', color: '#D32F2F', description: '', navIcon: '🔥', isPremium: false, navBar: false),
        AppSection(key: 'bookmarks', nameAr: 'المحفوظات',    icon: '📌', color: '#5D4037', description: '', navIcon: '📌', isPremium: false, navBar: false),
        AppSection(key: 'about',     nameAr: 'حول التطبيق',  icon: 'ℹ️', color: '#455A64', description: '', navIcon: 'ℹ️', isPremium: false, navBar: false),
      ];
    }
    if (AppConfig.cities.isEmpty) {
      AppConfig.cities = [
        const AppCity(nameEn: 'Tunis',    nameAr: 'تونس العاصمة', lat: 36.8065, lng: 10.1815),
        const AppCity(nameEn: 'Sfax',     nameAr: 'صفاقس',        lat: 34.7406, lng: 10.7603),
        const AppCity(nameEn: 'Sousse',   nameAr: 'سوسة',          lat: 35.8256, lng: 10.6369),
        const AppCity(nameEn: 'Bizerte',  nameAr: 'بنزرت',         lat: 37.2746, lng: 9.8736),
        const AppCity(nameEn: 'Gabes',    nameAr: 'قابس',          lat: 33.8833, lng: 10.0833),
        const AppCity(nameEn: 'Monastir', nameAr: 'المنستير',      lat: 35.7643, lng: 10.8113),
        const AppCity(nameEn: 'Nabeul',   nameAr: 'نابل',          lat: 36.4561, lng: 10.7376),
        const AppCity(nameEn: 'Djerba',   nameAr: 'جربة',          lat: 33.8076, lng: 10.8451),
      ];
    }
    if (AppConfig.newsFeeds.isEmpty) {
      AppConfig.newsFeeds = [
        NewsSource(name: 'موزاييك', url: 'https://www.mosaiquefm.net/ar/rss',     emoji: '📻', color: '#C8102E', category: 'تونس'),
        NewsSource(name: 'الشروق',  url: 'https://www.shemsfm.net/ar/rss',         emoji: '☀️', color: '#F57C00', category: 'تونس'),
        NewsSource(name: 'الجزيرة', url: 'https://www.aljazeera.net/ajax/rss/all', emoji: '🌍', color: '#388E3C', category: 'عربي'),
      ];
    }
    if (AppConfig.games.isEmpty) {
      AppConfig.games = [
        AppGame(key: 'guess_number', name: 'خمّن الرقم',     description: 'خمّن رقماً بين 1 و 100', icon: '🔢', color: '#1976D2'),
        AppGame(key: 'word_game',    name: 'لعبة الكلمات',   description: 'خمّن المدينة التونسية',  icon: '✏️', color: '#388E3C'),
        AppGame(key: 'math_game',    name: 'الحساب السريع',  description: 'اختبر سرعتك في الحساب', icon: '🧮', color: '#F57C00'),
        AppGame(key: 'trivia',       name: 'ثلاثية المعرفة', description: 'أسئلة ثقافية متنوعة',   icon: '🌐', color: '#7B1FA2'),
      ];
    }
  }
}
