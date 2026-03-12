import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';
import '../../services/api_service.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});
  @override
  State<ActivationScreen> createState() => _ActivState();
}

class _ActivState extends State<ActivationScreen> {
  final _ctrl = TextEditingController();
  bool   _loading = false;
  String? _err, _ok;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _activate() async {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _err = 'أدخل كود التفعيل');
      return;
    }
    setState(() { _loading = true; _err = null; _ok = null; });
    await context.read<AppController>().doActivate(_ctrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    final info = context.read<AppController>().activationInfo;
    switch (info?.status) {
      case ActivationStatus.valid:
        setState(() => _ok = 'تم التفعيل ✅ — متبقي ${info?.daysLeft ?? 0} يوم');
      case ActivationStatus.expired:
        setState(() => _err = '⏰ انتهت صلاحية الكود');
      case ActivationStatus.wrongDevice:
        setState(() => _err = '📵 الكود مرتبط بجهاز آخر');
      case ActivationStatus.invalidCode:
        setState(() => _err = '❌ الكود غير صحيح أو محذوف');
      case ActivationStatus.networkError:
        setState(() => _err = '🌐 تحقق من الاتصال بالإنترنت');
      default:
        setState(() => _err = '❌ حدث خطأ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [pr.withOpacity(0.9), pr, AppConfig.colorAccent],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          // إصلاح: SafeArea يمنع التداخل مع شريط التنقل السفلي
          bottom: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(child: Text(AppConfig.splashEmoji,
                      style: const TextStyle(fontSize: 46))),
                ),
                const SizedBox(height: 16),
                Text(AppConfig.appName,
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                Text(AppConfig.appSubtitle,
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('تفعيل التطبيق',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    if (_err != null) Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(_err!,
                          style: GoogleFonts.cairo(color: Colors.red.shade700),
                          textAlign: TextAlign.center),
                    ),
                    if (_ok != null) Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(_ok!,
                          style: GoogleFonts.cairo(color: Colors.green.shade700),
                          textAlign: TextAlign.center),
                    ),
                    TextField(
                      controller: _ctrl,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.cairo(
                          fontSize: 22, letterSpacing: 3, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _activate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pr, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text('تفعيل',
                                style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
