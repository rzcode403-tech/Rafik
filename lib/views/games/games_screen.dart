import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../models/app_config.dart';
import '../../models/news_article.dart';
import '../../services/api_service.dart';

// ── GamesScreen ───────────────────────────────────────────────
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  Widget _gameFor(String key) {
    switch (key) {
      case 'guess_number': return const GuessGame();
      case 'word_game':    return const WordGame();
      case 'math_game':    return const MathGame();
      case 'trivia':       return const TriviaGame();
      default:             return const GuessGame();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🎮 الألعاب')),
    body: SafeArea(
      top: false,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: AppConfig.games.length,
        itemBuilder: (c, i) {
          final g = AppConfig.games[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: g.colorObj.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(g.icon, style: const TextStyle(fontSize: 28))),
              ),
              title: Text(g.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16)),
              subtitle: Text(g.description,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
              trailing: Icon(Icons.play_circle_rounded, color: g.colorObj, size: 36),
              onTap: () => Navigator.push(c,
                  MaterialPageRoute(builder: (_) => _gameFor(g.key))),
            ),
          );
        },
      ),
    ),
  );
}

// ── GuessGame ─────────────────────────────────────────────────
class GuessGame extends StatefulWidget {
  const GuessGame({super.key});
  @override
  State<GuessGame> createState() => _GuessGameState();
}

class _GuessGameState extends State<GuessGame> {
  int _target = Random().nextInt(100) + 1;
  int _attempts = 0;
  String _msg = 'خمّن رقماً بين 1 و 100';
  bool _won = false;
  final _ctrl = TextEditingController();

  void _guess() {
    final n = int.tryParse(_ctrl.text);
    if (n == null) return;
    _attempts++;
    if (n == _target) {
      setState(() { _msg = '🎉 الرقم هو $_target! في $_attempts محاولة'; _won = true; });
    } else if (n < _target) {
      setState(() => _msg = 'أكبر ⬆️  (محاولة $_attempts)');
    } else {
      setState(() => _msg = 'أصغر ⬇️  (محاولة $_attempts)');
    }
    _ctrl.clear();
  }

  void _reset() => setState(() {
    _target = Random().nextInt(100) + 1; _attempts = 0;
    _msg = 'خمّن رقماً بين 1 و 100'; _won = false;
  });

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(title: const Text('🔢 خمّن الرقم')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
              const Text('🔢', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(_msg,
                  style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
            ]))),
            const SizedBox(height: 24),
            if (!_won) ...[
              TextField(
                controller: _ctrl, keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                onSubmitted: (_) => _guess(),
                decoration: const InputDecoration(hintText: '?'),
              ),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _guess,
                style: ElevatedButton.styleFrom(
                    backgroundColor: pr, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('تخمين',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
              )),
            ] else SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('لعبة جديدة',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── WordGame ──────────────────────────────────────────────────
class WordGame extends StatefulWidget {
  const WordGame({super.key});
  @override
  State<WordGame> createState() => _WordGameState();
}

class _WordGameState extends State<WordGame> {
  static const _words = [
    'تونس','قرطاج','جربة','سوسة','المهدية',
    'بنزرت','قفصة','تطاوين','نفطة','دوز',
    'منوبة','زغوان','سيدي','بوزيد','صفاقس',
  ];
  late String _word;
  late String _hidden;
  List<String> _guessed = [];
  int _lives = 6;
  bool _won = false, _lost = false;
  final _ctrl = TextEditingController();

  @override
  void initState() { super.initState(); _start(); }

  void _start() {
    _word    = _words[Random().nextInt(_words.length)];
    _guessed = []; _lives = 6; _won = false; _lost = false;
    _updateHidden();
  }

  void _updateHidden() {
    setState(() {
      _hidden = _word.split('').map((c) => _guessed.contains(c) ? c : '_').join(' ');
      if (!_hidden.contains('_')) _won = true;
    });
  }

  void _guess() {
    final c = _ctrl.text.trim(); _ctrl.clear();
    if (c.isEmpty || _guessed.contains(c)) return;
    _guessed.add(c);
    if (!_word.contains(c)) setState(() { _lives--; if (_lives <= 0) _lost = true; });
    _updateHidden();
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(title: const Text('✏️ لعبة الكلمات')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              '${'❤️ ' * _lives}${'🖤 ' * (6 - _lives)}',
              style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              Text(_hidden,
                  style: const TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              if (_won) Padding(padding: const EdgeInsets.only(top: 16),
                  child: Text('🎉 الكلمة هي: $_word',
                      style: GoogleFonts.cairo(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 16))),
              if (_lost) Padding(padding: const EdgeInsets.only(top: 16),
                  child: Text('💔 الكلمة كانت: $_word',
                      style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16))),
            ]))),
            const SizedBox(height: 20),
            if (!_won && !_lost) ...[
              TextField(
                controller: _ctrl, maxLength: 1, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                onSubmitted: (_) => _guess(),
                decoration: const InputDecoration(hintText: 'حرف', counterText: ''),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _guess,
                style: ElevatedButton.styleFrom(
                    backgroundColor: pr, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('تخمين',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
              )),
            ] else SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => setState(_start),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('لعبة جديدة',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── MathGame ──────────────────────────────────────────────────
class MathGame extends StatefulWidget {
  const MathGame({super.key});
  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  int _a = 0, _b = 0, _score = 0;
  String _op = '+';
  String? _feedback;
  final _ctrl = TextEditingController();

  @override
  void initState() { super.initState(); _newQ(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _newQ() {
    final r   = Random();
    final ops = ['+', '-', 'x'];
    _op = ops[r.nextInt(3)];
    if (_op == 'x') { _a = r.nextInt(10) + 1; _b = r.nextInt(10) + 1; }
    else             { _a = r.nextInt(20) + 1; _b = r.nextInt(20) + 1; }
    setState(() => _feedback = null);
    _ctrl.clear();
  }

  void _check() {
    final ans = int.tryParse(_ctrl.text);
    if (ans == null) return;
    final correct = _op == '+' ? _a + _b : _op == '-' ? _a - _b : _a * _b;
    if (ans == correct) {
      _score++;
      setState(() => _feedback = 'صح! ✅');
      Future.delayed(const Duration(milliseconds: 700), _newQ);
    } else {
      setState(() => _feedback = 'الصواب: $correct ❌');
      Future.delayed(const Duration(seconds: 1), _newQ);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    final opDisplay = _op == 'x' ? '×' : _op;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧮 الحساب السريع'),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(left: 16),
            child: Text('🏆 $_score',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16))))],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Card(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
              Text('$_a  $opDisplay  $_b  =  ?',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              if (_feedback != null) ...[
                const SizedBox(height: 16),
                Text(_feedback!,
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              ],
            ]))),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl, keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              onSubmitted: (_) => _check(),
              decoration: const InputDecoration(hintText: '؟'),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _check,
              style: ElevatedButton.styleFrom(
                  backgroundColor: pr, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('إجابة',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── TriviaGame ────────────────────────────────────────────────
class TriviaGame extends StatefulWidget {
  const TriviaGame({super.key});
  @override
  State<TriviaGame> createState() => _TriviaGameState();
}

class _TriviaGameState extends State<TriviaGame> {
  List<TriviaQuestion> _qs = [];
  int _idx = 0, _score = 0;
  bool _loading = true;
  String? _selected;
  bool _answered = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await TriviaService.fetch();
    setState(() { _qs = r; _loading = false; });
  }

  void _answer(String opt) {
    if (_answered) return;
    setState(() {
      _selected = opt; _answered = true;
      if (opt == _qs[_idx].correct) _score++;
    });
  }

  void _next() {
    if (_idx < _qs.length - 1) {
      setState(() { _idx++; _selected = null; _answered = false; });
    } else {
      setState(() => _idx = _qs.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;

    if (_loading) return Scaffold(
      appBar: AppBar(title: const Text('🌐 ثلاثية المعرفة')),
      body: const Center(child: CircularProgressIndicator()));

    if (_qs.isEmpty) return Scaffold(
      appBar: AppBar(title: const Text('🌐 ثلاثية المعرفة')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😕', style: TextStyle(fontSize: 60)),
        Text('تعذّر تحميل الأسئلة', style: GoogleFonts.cairo(fontSize: 16)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load, child: Text('إعادة', style: GoogleFonts.cairo())),
      ])));

    if (_idx >= _qs.length) return Scaffold(
      appBar: AppBar(title: const Text('🌐 ثلاثية المعرفة')),
      body: Center(child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(padding: const EdgeInsets.all(32), child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            const Text('🏆', style: TextStyle(fontSize: 72)),
            Text('النتيجة النهائية',
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('$_score / ${_qs.length}',
                style: GoogleFonts.cairo(
                    fontSize: 40, fontWeight: FontWeight.w900, color: pr)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => setState(() {
                _idx = 0; _score = 0; _selected = null; _answered = false; _qs = [];
                _load();
              }),
              style: ElevatedButton.styleFrom(
                  backgroundColor: pr, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('لعبة جديدة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            )),
          ],
        )),
      )));

    final q = _qs[_idx];
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌐 ثلاثية المعرفة'),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(left: 16),
            child: Text('$_score/${_qs.length}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700))))],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_idx + 1) / _qs.length, color: pr,
                backgroundColor: Colors.grey.shade200, minHeight: 6),
            ),
            const SizedBox(height: 20),
            Card(child: Padding(padding: const EdgeInsets.all(20),
                child: Text(q.question,
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, height: 1.6),
                    textAlign: TextAlign.center))),
            const SizedBox(height: 16),
            ...q.options.map((opt) {
              Color? bg, fg;
              if (_answered) {
                if (opt == q.correct)   { bg = Colors.green.shade100; fg = Colors.green.shade800; }
                else if (opt == _selected) { bg = Colors.red.shade100; fg = Colors.red.shade800; }
              }
              return GestureDetector(
                onTap: () => _answer(opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg ?? Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selected == opt
                          ? (opt == q.correct ? Colors.green : Colors.red)
                          : Colors.grey.shade200,
                      width: 1.5),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: Text(opt,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600, fontSize: 14,
                          color: fg ?? Colors.black87),
                      textAlign: TextAlign.center),
                ),
              );
            }),
            if (_answered) ...[
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                    backgroundColor: pr, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(
                  _idx < _qs.length - 1 ? 'السؤال التالي ⟵' : 'عرض النتائج 🏆',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700)),
              )),
            ],
          ]),
        ),
      ),
    );
  }
}
