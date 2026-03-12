import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/app_config.dart';
import '../../models/news_article.dart';
import '../../services/api_service.dart';

// ── CurrencyScreen ────────────────────────────────────────────
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  String _from = 'TND', _to = 'USD';
  double _amount = 1;
  double? _result;
  final _ctrl = TextEditingController(text: '1');

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final st  = context.watch<AppController>();
    final cur = st.currency;
    final pr  = AppConfig.colorPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('💱 محوّل العملات')),
      body: SafeArea(
        top: false,
        child: cur == null
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text('جاري تحميل أسعار الصرف...', style: GoogleFonts.cairo()),
              ]))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(children: [
                  // حقل المبلغ
                  TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      labelStyle: GoogleFonts.cairo(),
                      suffixIcon: const Icon(Icons.edit),
                    ),
                    onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 1),
                  ),
                  const SizedBox(height: 16),
                  // اختيار العملات
                  Row(children: [
                    Expanded(child: _CurrSel(value: _from, onChange: (v) => setState(() => _from = v!))),
                    IconButton(
                      icon: Icon(Icons.swap_horiz_rounded, size: 30, color: pr),
                      onPressed: () => setState(() { final t = _from; _from = _to; _to = t; }),
                    ),
                    Expanded(child: _CurrSel(value: _to, onChange: (v) => setState(() => _to = v!))),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _result = cur.convert(_amount, _from, _to)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pr, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text('تحويل', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 20),
                    Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
                      Text('النتيجة',
                          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 10),
                      Text('${_result!.toStringAsFixed(4)} $_to',
                          style: GoogleFonts.cairo(
                              fontSize: 30, fontWeight: FontWeight.w900, color: pr)),
                      const SizedBox(height: 6),
                      Text('$_amount $_from = ${_result!.toStringAsFixed(4)} $_to',
                          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                    ]))),
                  ],
                  const SizedBox(height: 24),
                  // جدول الأسعار
                  Text('أسعار الصرف مقابل الدينار التونسي',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  ...CurrencyModel.supported.entries.map((e) {
                    final rate = cur.rates[e.key];
                    if (rate == null) return const SizedBox.shrink();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Text(e.value.$1, style: const TextStyle(fontSize: 24)),
                        title: Text('${e.value.$2} (${e.key})',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                        trailing: Text('${rate.toStringAsFixed(3)} د.ت',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: pr)),
                      ),
                    );
                  }),
                ]),
              ),
      ),
    );
  }
}

class _CurrSel extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChange;
  const _CurrSel({required this.value, required this.onChange});
  @override
  Widget build(BuildContext context) {
    final allItems = [
      const DropdownMenuItem(value: 'TND', child: Text('🇹🇳 دينار')),
      ...CurrencyModel.supported.entries.map((e) =>
          DropdownMenuItem(value: e.key, child: Text('${e.value.$1} ${e.value.$2}'))),
    ];
    final validValue = allItems.any((i) => i.value == value) ? value : 'TND';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          style: GoogleFonts.cairo(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
          items: allItems,
          onChanged: onChange,
        ),
      ),
    );
  }
}

// ── TranslationScreen ─────────────────────────────────────────
class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});
  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final _ctrl   = TextEditingController();
  String _from  = 'ar', _to = 'fr', _result = '';
  bool _loading = false;

  static const _langs = {
    'ar': ('🇸🇦', 'عربي'),
    'fr': ('🇫🇷', 'Français'),
    'en': ('🇺🇸', 'English'),
    'de': ('🇩🇪', 'Deutsch'),
    'es': ('🇪🇸', 'Español'),
    'it': ('🇮🇹', 'Italiano'),
    'tr': ('🇹🇷', 'Türkçe'),
  };

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _translate() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _result = ''; });
    final r = await TranslationService.translate(_ctrl.text.trim(), _from, _to);
    setState(() { _loading = false; _result = r ?? 'فشلت الترجمة'; });
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(title: const Text('🌍 الترجمة')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // نص الإدخال
            TextField(
              controller: _ctrl, maxLines: 4,
              style: GoogleFonts.cairo(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'أدخل النص هنا...',
                hintStyle: GoogleFonts.cairo(color: Colors.grey),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            // اختيار اللغات
            Row(children: [
              Expanded(child: _LangSel(value: _from, onChange: (v) => setState(() => _from = v!))),
              IconButton(
                icon: Icon(Icons.swap_horiz_rounded, size: 28, color: pr),
                onPressed: () => setState(() { final t = _from; _from = _to; _to = t; }),
              ),
              Expanded(child: _LangSel(value: _to, onChange: (v) => setState(() => _to = v!))),
            ]),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loading ? null : _translate,
              style: ElevatedButton.styleFrom(
                backgroundColor: pr, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text('ترجم', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الترجمة', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  // ⚠️ إصلاح ترميز الخطوط: نص منتقى بشكل صحيح
                  SelectableText(_result,
                      style: GoogleFonts.cairo(fontSize: 16, height: 1.7)),
                  const SizedBox(height: 10),
                  Row(children: [
                    TextButton.icon(
                      onPressed: () => Clipboard.setData(ClipboardData(text: _result)),
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text('نسخ', style: GoogleFonts.cairo()),
                    ),
                  ]),
                ],
              ))),
            ],
          ]),
        ),
      ),
    );
  }
}

class _LangSel extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChange;
  const _LangSel({required this.value, required this.onChange});
  static const _langs = {
    'ar': ('🇸🇦', 'عربي'), 'fr': ('🇫🇷', 'Français'),
    'en': ('🇺🇸', 'English'), 'de': ('🇩🇪', 'Deutsch'),
    'es': ('🇪🇸', 'Español'), 'it': ('🇮🇹', 'Italiano'), 'tr': ('🇹🇷', 'Türkçe'),
  };
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        style: GoogleFonts.cairo(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
        items: _langs.entries.map((e) => DropdownMenuItem(
          value: e.key,
          child: Text('${e.value.$1} ${e.value.$2}'),
        )).toList(),
        onChanged: onChange,
      ),
    ),
  );
}
