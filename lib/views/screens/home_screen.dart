import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';
import '../../models/news_article.dart';
import '../widgets/section_router.dart';
import 'article_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppController>();
    final pr = AppConfig.colorPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Icon(st.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: st.toggleDark,
          ),
          IconButton(
            icon: const Icon(Icons.location_city_outlined),
            onPressed: () => _cityPicker(context, st),
          ),
        ],
      ),
      body: st.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: st.loadAll,
              // إصلاح: SafeArea يمنع تغطية شريط التنقل السفلي على المحتوى
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Hero card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [pr, pr.withOpacity(0.75)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('أهلاً 👋',
                              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
                          Text(
                            st.selectedCityAr.isNotEmpty
                                ? st.selectedCityAr
                                : (AppConfig.cities.firstOrNull?.nameAr ?? 'تونس'),
                            style: GoogleFonts.cairo(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          if (st.weather != null)
                            Text(
                              '${st.weather!.emoji} ${st.weather!.temp.round()}° — ${st.weather!.description}',
                              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                            ),
                        ])),
                        Text(st.weather?.emoji ?? AppConfig.splashEmoji,
                            style: const TextStyle(fontSize: 52)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Text('الخدمات',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    _SectionsGrid(),
                    const SizedBox(height: 20),
                    if (st.news.isNotEmpty) ...[
                      Text('آخر الأخبار',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...st.news.take(4).map((a) => _NewsCard(a)),
                    ],
                  ]),
                ),
              ),
            ),
    );
  }

  void _cityPicker(BuildContext ctx, AppController st) {
    showModalBottomSheet(
      context: ctx,
      useSafeArea: true, // إصلاح: يمنع التداخل مع شريط التنقل
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('اختر مدينتك',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            ...AppConfig.cities.map((c) => ListTile(
              title: Text(c.nameAr, style: GoogleFonts.cairo()),
              trailing: st.selectedCity == c.nameEn
                  ? Icon(Icons.check, color: AppConfig.colorPrimary)
                  : null,
              onTap: () { st.setCity(c.nameEn, c.nameAr); Navigator.pop(ctx); },
            )),
          ]),
        ),
      ),
    );
  }
}

class _SectionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sections = AppConfig.sections.where((s) => !s.navBar).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9),
      itemCount: sections.length,
      itemBuilder: (c, i) {
        final s = sections[i];
        return GestureDetector(
          onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => sectionScreen(s))),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(c).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: s.colorObj.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(s.nameAr,
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle a;
  const _NewsCard(this.a);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(
        context, MaterialPageRoute(builder: (_) => ArticleScreen(article: a))),
    child: Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.source,
              style: GoogleFonts.cairo(
                  fontSize: 11, color: AppConfig.colorPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(a.title,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      )),
    ),
  );
}
