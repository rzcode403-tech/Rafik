import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/app_config.dart';
import '../models/news_article.dart';
import '../services/api_service.dart';

class AppController extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────
  bool isDark        = false;
  bool isLoading     = false;
  bool configLoaded  = false;
  bool isActivated   = false;
  bool hasInternet   = true;

  String selectedCity   = '';
  String selectedCityAr = '';

  WeatherModel?  weather;
  PrayerModel?   prayer;
  CurrencyModel? currency;
  List<NewsArticle> news = [];

  ActivationResult? activationInfo;
  SharedPreferences? _prefs;

  // ── City helper ────────────────────────────────────────────
  AppCity get currentCity {
    if (AppConfig.cities.isEmpty)
      return const AppCity(nameEn: 'Tunis', nameAr: 'تونس العاصمة', lat: 36.8065, lng: 10.1815);
    if (selectedCity.isEmpty) return AppConfig.cities.first;
    return AppConfig.cities.firstWhere(
      (c) => c.nameEn == selectedCity, orElse: () => AppConfig.cities.first);
  }

  // ── Init ───────────────────────────────────────────────────
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    isDark         = _prefs?.getBool('dark')      ?? false;
    selectedCity   = _prefs?.getString('city')    ?? '';
    selectedCityAr = _prefs?.getString('city_ar') ?? '';

    // تحقق من الاتصال
    final con = await Connectivity().checkConnectivity();
    hasInternet = con != ConnectivityResult.none;

    // جلب الإعدادات من الخادم
    if (hasInternet) await ConfigService.fetchAndApply();

    configLoaded = true;

    if (selectedCity.isEmpty && AppConfig.cities.isNotEmpty) {
      selectedCity   = AppConfig.cities.first.nameEn;
      selectedCityAr = AppConfig.cities.first.nameAr;
    }

    // ⚠️ تحقق من التفعيل دائماً من الخادم
    activationInfo = await ActivationService.checkStatus();
    isActivated = activationInfo?.status == ActivationStatus.valid
        || !AppConfig.activationRequired;

    notifyListeners();
    if (isActivated) await loadAll();
  }

  // ── Load data ──────────────────────────────────────────────
  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final city = currentCity;
    await Future.wait([
      WeatherService.fetch(city.lat, city.lng).then((v) { if (v != null) weather  = v; }),
      PrayerService.fetch(city.nameEn).then((v)          { if (v != null) prayer   = v; }),
      CurrencyService.fetch().then((v)                   { if (v != null) currency = v; }),
      NewsService.fetch().then((v)                       { news = v; }),
    ]);
    isLoading = false;
    notifyListeners();
  }

  // ── Activation ─────────────────────────────────────────────
  Future<void> doActivate(String code) async {
    final r = await ActivationService.activate(code);
    activationInfo = r;
    isActivated = r.status == ActivationStatus.valid;
    if (isActivated) await loadAll();
    notifyListeners();
  }

  // ── Preferences ────────────────────────────────────────────
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
}
