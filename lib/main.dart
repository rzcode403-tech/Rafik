import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/app_controller.dart';
import 'models/app_config.dart';
import 'views/shell/root_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('fr', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // صحح مشكلة شريط النظام
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  // اسمح للمحتوى بالامتداد خلف شريط النظام
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppController()..init(),
      child: const RafiqApp(),
    ),
  );
}

class RafiqApp extends StatelessWidget {
  const RafiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      themeMode: ctrl.isDark ? ThemeMode.dark : ThemeMode.light,
      // دعم العربية والفرنسية بشكل صحيح
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // إصلاح حجم الخطوط عند تغيير إعدادات النظام
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
      home: const RootRouter(),
    );
  }

  ThemeData _buildTheme(bool dark) {
    final pr = AppConfig.colorPrimary;
    final bg = AppConfig.colorDarkBg;
    final base = dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pr,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: pr,
        secondary: AppConfig.colorAccent,
      ),
      scaffoldBackgroundColor: dark ? bg : const Color(0xFFF0F2F5),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: dark ? bg : const Color(0xFFF0F2F5),
        foregroundColor: dark ? Colors.white : const Color(0xFF1A1A2E),
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: dark ? Colors.white : const Color(0xFF1A1A2E)),
        // إصلاح شريط الحالة
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF21262D) : const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: pr, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF0D1117) : Colors.white,
        selectedItemColor: pr,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
