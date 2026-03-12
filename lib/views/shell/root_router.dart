import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';
import '../../services/api_service.dart';
import '../screens/activation_screen.dart';
import 'main_shell.dart';

// ── RootRouter ────────────────────────────────────────────────
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppController>();
    if (!s.configLoaded) return const _SplashScreen();
    if (AppConfig.activationRequired && !s.isActivated)
      return const ActivationScreen();
    return const MainShell();
  }
}

// ── Splash ────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConfig.colorPrimary, AppConfig.colorPrimary.withOpacity(0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(AppConfig.splashEmoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          Text(AppConfig.appName,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(AppConfig.appSubtitle,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 48),
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ])),
      ),
    ),
  );
}
