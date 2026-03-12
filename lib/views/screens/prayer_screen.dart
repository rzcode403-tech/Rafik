import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st  = context.watch<AppController>();
    final pr  = AppConfig.colorPrimary;
    final city = st.selectedCityAr.isNotEmpty ? st.selectedCityAr : 'تونس';
    final prayer = st.prayer;

    return Scaffold(
      appBar: AppBar(title: Text('🕌 أوقات الصلاة — $city')),
      body: prayer == null
          ? Center(child: st.isLoading
              ? const CircularProgressIndicator()
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🕌', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text('لم تُحمَّل أوقات الصلاة', style: GoogleFonts.cairo(fontSize: 16)),
                  TextButton(onPressed: st.loadAll, child: Text('إعادة', style: GoogleFonts.cairo())),
                ]))
          : SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: st.loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(children: [
                    // بطاقة الصلاة القادمة
                    if (prayer.nextPrayer != null) Builder(builder: (_) {
                      final next = prayer.nextPrayer!;
                      final dt   = next['dt'] as DateTime;
                      final diff = dt.difference(DateTime.now());
                      final h    = diff.inHours;
                      final m    = diff.inMinutes % 60;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [pr, pr.withOpacity(0.75)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(children: [
                          Text('الصلاة القادمة', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('${next['icon']} ${next['name']}',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                          Text(next['time'] as String,
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              h > 0 ? 'بعد ${h}س ${m}د' : 'بعد ${m} دقيقة',
                              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                      );
                    }),
                    // قائمة الصلوات
                    ...prayer.prayerList.map((item) {
                      final isNext = prayer.nextPrayer?['name'] == item['name'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isNext ? pr.withOpacity(0.08) : null,
                        child: ListTile(
                          leading: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: isNext ? pr : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(item['icon'] as String,
                                style: const TextStyle(fontSize: 22))),
                          ),
                          title: Text(item['name'] as String,
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: isNext ? pr : null,
                                  fontSize: 15)),
                          trailing: Text(item['time'] as String,
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w800, fontSize: 20,
                                  color: isNext ? pr : null)),
                        ),
                      );
                    }),
                  ]),
                ),
              ),
            ),
    );
  }
}
