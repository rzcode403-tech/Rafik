import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';
import '../screens/home_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/prayer_screen.dart';
import '../screens/news_screen.dart';
import '../screens/more_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    // ⚠️ مراقبة دورة حياة التطبيق لكشف إلغاء التفعيل
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند عودة التطبيق للواجهة → تحقق من التفعيل فوراً
    if (state == AppLifecycleState.resumed) {
      context.read<AppController>().recheckActivation();
    }
  }

  List<AppSection> get _navSections =>
      AppConfig.sections.where((s) => s.navBar).toList();

  Widget _buildScreen(AppSection s) {
    switch (s.key) {
      case 'home':    return const HomeScreen();
      case 'weather': return const WeatherScreen();
      case 'prayer':  return const PrayerScreen();
      case 'news':    return const NewsScreen();
      case 'more':    return const MoreScreen();
      default:        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = _navSections;
    if (nav.isEmpty) return const HomeScreen();
    final idx = _idx.clamp(0, nav.length - 1);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: idx,
        children: nav.map(_buildScreen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 10),
        items: nav.map((s) => BottomNavigationBarItem(
          icon: Text(s.navIcon, style: const TextStyle(fontSize: 22)),
          label: s.nameAr,
        )).toList(),
      ),
    );
  }
}
