import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_config.dart';
import '../screens/currency_screen.dart';
import '../screens/translation_screen.dart';
import '../screens/jokes_screen.dart';
import '../screens/games_screen.dart';
import '../screens/tv_screen.dart';
import '../screens/radio_screen.dart';
import '../screens/trends_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/about_screen.dart';

Widget sectionScreen(AppSection s) {
  switch (s.key) {
    case 'currency':  return const CurrencyScreen();
    case 'translate': return const TranslationScreen();
    case 'jokes':     return const JokesScreen();
    case 'games':     return const GamesScreen();
    case 'tv':        return const TVScreen();
    case 'radio':     return const RadioScreen();
    case 'trending':  return const TrendsScreen();
    case 'bookmarks': return const BookmarksScreen();
    case 'about':     return const AboutScreen();
    default:          return _FallbackScreen(s);
  }
}

class _FallbackScreen extends StatelessWidget {
  final AppSection s;
  const _FallbackScreen(this.s);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(s.nameAr)),
    body: SafeArea(
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(s.icon, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(s.nameAr,
            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w700)),
      ])),
    ),
  );
}
