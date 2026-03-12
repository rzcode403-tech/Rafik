import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  static const _weekdays = ['الإثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
  static const _weatherDesc = {
    0: ('☀️','صافٍ'), 1: ('🌤️','غيوم خفيفة'), 2: ('⛅','غائم جزئياً'),
    3: ('☁️','غائم'), 51: ('🌦️','رذاذ خفيف'), 61: ('🌧️','مطر خفيف'),
    63: ('🌧️','مطر'), 71: ('🌨️','ثلج خفيف'), 80: ('⛈️','زخات مطر'),
    95: ('⛈️','عاصفة رعدية'),
  };

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppController>();
    final w  = st.weather;
    final pr = AppConfig.colorPrimary;
    final city = st.selectedCityAr.isNotEmpty ? st.selectedCityAr : 'تونس';

    return Scaffold(
      appBar: AppBar(title: Text('🌤️ الطقس — $city')),
      body: w == null
          ? Center(child: st.isLoading
              ? const CircularProgressIndicator()
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('😶‍🌫️', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text('لا تتوفر بيانات الطقس', style: GoogleFonts.cairo(fontSize: 16)),
                  TextButton(onPressed: st.loadAll, child: Text('إعادة المحاولة', style: GoogleFonts.cairo())),
                ]))
          : SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: st.loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(children: [
                    // بطاقة الطقس الرئيسية
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [pr, pr.withOpacity(0.7)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(children: [
                        Text(w.emoji, style: const TextStyle(fontSize: 72)),
                        const SizedBox(height: 8),
                        Text('${w.temp.round()}°',
                            style: GoogleFonts.cairo(
                                fontSize: 68, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text(w.description,
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        Text(city,
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 20),
                        // إحصاءات
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          _Stat('💨', '${w.windspeed.round()} km/h', 'الرياح'),
                          Container(width: 1, height: 40, color: Colors.white30),
                          _Stat('🌡️', '${w.feelsLike.round()}°', 'يبدو'),
                          Container(width: 1, height: 40, color: Colors.white30),
                          _Stat('💧', w.isRaining ? 'ممطر' : 'جافّ', 'الأمطار'),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // توقعات الأسبوع
                    if (w.daily.isNotEmpty) Card(
                      child: Padding(padding: const EdgeInsets.all(16), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📅 توقعات الأسبوع',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 12),
                          ...w.daily.asMap().entries.map((e) {
                            final day = e.value;
                            final date = day['date'] as String;
                            final dt   = DateTime.tryParse(date);
                            final name = dt != null
                                ? _weekdays[(dt.weekday - 1) % 7]
                                : date;
                            final wcode = (day['weathercode'] as num?)?.toInt() ?? 0;
                            final wInfo = _weatherDesc[wcode] ?? ('🌤️', '');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                SizedBox(width: 80,
                                    child: Text(name,
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.w600, fontSize: 13))),
                                Text(wInfo.$1, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(wInfo.$2,
                                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12))),
                                Text(
                                  '${(day['max'] as double).round()}° / ${(day['min'] as double).round()}°',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ]),
                            );
                          }),
                        ],
                      )),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon, value, label;
  const _Stat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(icon, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 4),
    Text(value,
        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
    Text(label, style: GoogleFonts.cairo(color: Colors.white60, fontSize: 11)),
  ]);
}
