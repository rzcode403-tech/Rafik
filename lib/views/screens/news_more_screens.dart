import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';
import '../../models/news_article.dart';
import '../../services/api_service.dart';
import '../../core/database.dart';
import '../widgets/section_router.dart';
import 'article_screen.dart';

// ── NewsScreen ────────────────────────────────────────────────
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<String> get _cats => ['الكل', ...AppConfig.newsFeeds.map((f) => f.category).toSet()];

  @override
  void initState() { super.initState(); _tab = TabController(length: _cats.length, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppController>();
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('📰 الأخبار'),
        bottom: TabBar(
          controller: _tab, isScrollable: true,
          indicatorColor: pr, labelColor: pr,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
          tabs: _cats.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tab,
          children: _cats.map((cat) {
            final fl = cat == 'الكل'
                ? st.news
                : st.news.where((a) =>
                    AppConfig.newsFeeds.any((f) => f.category == cat && f.name == a.source)).toList();
            if (fl.isEmpty) return Center(child: st.isLoading
                ? const CircularProgressIndicator()
                : Text('لا توجد أخبار', style: GoogleFonts.cairo()));
            return RefreshIndicator(
              onRefresh: st.loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: fl.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ArticleScreen(article: fl[i]))),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fl[i].source,
                            style: GoogleFonts.cairo(fontSize: 11, color: pr, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(fl[i].title,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── MoreScreen ────────────────────────────────────────────────
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final sections = AppConfig.sections.where((s) => !s.navBar).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('⚡ المزيد')),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
          itemCount: sections.length,
          itemBuilder: (c, i) {
            final s = sections[i];
            return GestureDetector(
              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => sectionScreen(s))),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(c).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: s.colorObj.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}

// ── TrendsScreen ──────────────────────────────────────────────
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});
  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  List<NewsArticle> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await NewsService.fetchTrending();
    setState(() { _items = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(title: const Text('🔥 الترند')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: _items.length,
                  itemBuilder: (c, i) {
                    final a = _items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: pr.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text('${i + 1}',
                              style: TextStyle(color: pr, fontWeight: FontWeight.w900, fontSize: 16))),
                        ),
                        title: Text(a.title,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(a.source,
                            style: GoogleFonts.cairo(fontSize: 11, color: pr)),
                        onTap: () => Navigator.push(c,
                            MaterialPageRoute(builder: (_) => ArticleScreen(article: a))),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

// ── BookmarksScreen ───────────────────────────────────────────
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bm = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final b = await AppDB.getAll();
    setState(() => _bm = b);
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف الكل', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('هل تريد حذف جميع المحفوظات؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف الكل', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) { await AppDB.deleteAll(); await _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('📌 المحفوظات'),
        actions: [if (_bm.isNotEmpty)
          IconButton(icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: _deleteAll)],
      ),
      body: SafeArea(
        top: false,
        child: _bm.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📌', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Text('لا توجد مقالات محفوظة', style: GoogleFonts.cairo(fontSize: 16)),
                Text('اضغط "حفظ" في أي خبر', style: GoogleFonts.cairo(color: Colors.grey)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _bm.length,
                itemBuilder: (_, i) {
                  final b = _bm[i];
                  return Dismissible(
                    key: Key(b['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await AppDB.delete(b['id'] as int);
                      setState(() => _bm.removeAt(i));
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: pr.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Center(child: Text('📰', style: TextStyle(fontSize: 20))),
                        ),
                        title: Text(b['title'] as String, maxLines: 2,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(b['source'] as String,
                            style: GoogleFonts.cairo(fontSize: 11, color: pr)),
                        onTap: () async {
                          final uri = Uri.tryParse(b['url'] as String);
                          if (uri != null)
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ── AboutScreen ───────────────────────────────────────────────
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(title: const Text('ℹ️ حول التطبيق')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [pr, pr.withOpacity(0.75)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(child: Text(AppConfig.splashEmoji,
                      style: const TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 16),
                Text(AppConfig.appName,
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                Text(AppConfig.appSubtitle,
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                Text('الإصدار ${AppConfig.appVersion}',
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 20),
            _InfoCard('🎯 ما هو ${AppConfig.appName}؟',
                'تطبيق ذكي شامل مصمم للمستخدم التونسي.'),
            _InfoCard('📡 الأقسام',
                AppConfig.sections.map((s) => '${s.icon} ${s.nameAr}').join('  •  ')),
            _InfoCard('🔒 الخصوصية', 'جميع بياناتك تُحفظ على جهازك فقط.'),
          ]),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, body;
  const _InfoCard(this.title, this.body);
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        Text(body, style: GoogleFonts.cairo(fontSize: 13, height: 1.7, color: Colors.grey.shade600)),
      ],
    )),
  );
}
