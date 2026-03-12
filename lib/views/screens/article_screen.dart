import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database.dart';
import '../../models/app_config.dart';
import '../../models/news_article.dart';

class ArticleScreen extends StatelessWidget {
  final NewsArticle article;
  const ArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(title: Text(article.source)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(article.title,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 12),
            if (article.description.isNotEmpty)
              Text(article.description,
                  style: GoogleFonts.cairo(
                      fontSize: 14, height: 1.8, color: Colors.grey.shade600)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () => AppDB.save(article),
                icon: const Icon(Icons.bookmark_outline, size: 18),
                label: Text('حفظ', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: pr, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(article.url);
                  if (uri != null)
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: Text('فتح', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
