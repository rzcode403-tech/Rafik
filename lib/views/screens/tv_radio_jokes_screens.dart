import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import '../../models/app_config.dart';
import '../../services/api_service.dart';

// ══════════════════════════════════════════════════════════════
// TV SCREEN
// ══════════════════════════════════════════════════════════════
class TVScreen extends StatefulWidget {
  const TVScreen({super.key});
  @override
  State<TVScreen> createState() => _TVScreenState();
}

class _TVScreenState extends State<TVScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  VideoPlayerController? _vpc;
  TVChannel? _playing;
  bool _loading = false, _error = false, _full = false;

  List<String> get _cats => ['الكل', ...AppConfig.tvChannels.map((c) => c.category).toSet()];

  @override
  void initState() { super.initState(); _tab = TabController(length: _cats.length, vsync: this); }

  @override
  void dispose() {
    _vpc?.dispose(); _tab.dispose();
    if (_full) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  List<TVChannel> get _filtered {
    final cat = _cats[_tab.index];
    if (cat == 'الكل') return AppConfig.tvChannels;
    return AppConfig.tvChannels.where((c) => c.category == cat).toList();
  }

  Future<void> _play(TVChannel ch) async {
    setState(() { _loading = true; _error = false; _playing = ch; });
    await _vpc?.dispose();
    try {
      _vpc = VideoPlayerController.networkUrl(Uri.parse(ch.streamUrl));
      await _vpc!.initialize();
      await _vpc!.setLooping(true);
      await _vpc!.play();
      setState(() => _loading = false);
    } catch (_) { setState(() { _loading = false; _error = true; }); }
  }

  void _toggleFull() {
    setState(() => _full = !_full);
    if (_full) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_full && _playing != null) return _buildFullscreen();
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('📡 القنوات'),
        bottom: TabBar(
          controller: _tab, isScrollable: true,
          indicatorColor: pr, labelColor: pr,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _cats.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          if (_playing != null) _buildPlayer(pr),
          Expanded(child: TabBarView(
            controller: _tab,
            children: List.generate(_cats.length, (_) {
              final list = _filtered;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final ch   = list[i];
                  final isP  = _playing?.name == ch.name;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isP ? pr.withOpacity(0.1) : null,
                    child: ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                            color: pr.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(ch.flag, style: const TextStyle(fontSize: 22))),
                      ),
                      title: Text(ch.name,
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700, fontSize: 14,
                              color: isP ? pr : null)),
                      subtitle: Row(children: [
                        Text(ch.category, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                        if (ch.isHd) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                                color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text('HD',
                                style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                      trailing: Icon(
                        isP ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
                        color: pr, size: 32),
                      onTap: () => isP
                          ? setState(() { _vpc?.pause(); _playing = null; })
                          : _play(ch),
                    ),
                  );
                },
              );
            }),
          )),
        ]),
      ),
    );
  }

  Widget _buildPlayer(Color pr) => Container(
    color: Colors.black, height: 220,
    child: Stack(alignment: Alignment.center, children: [
      if (_vpc != null && _vpc!.value.isInitialized && !_error)
        SizedBox.expand(child: FittedBox(fit: BoxFit.contain,
          child: SizedBox(
            width:  _vpc!.value.size.width,
            height: _vpc!.value.size.height,
            child:  VideoPlayer(_vpc!))))
      else if (_error)
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
          Text('تعذّر التشغيل', style: GoogleFonts.cairo(color: Colors.white60)),
          TextButton(
            onPressed: () => _play(_playing!),
            child: Text('إعادة', style: GoogleFonts.cairo(color: Colors.white))),
        ])
      else const CircularProgressIndicator(color: Colors.white),
      Positioned(bottom: 0, left: 0, right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black54,
          child: Row(children: [
            Text(_playing!.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(_playing!.name,
                style: GoogleFonts.cairo(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
            if (_vpc != null && _vpc!.value.isInitialized)
              IconButton(
                icon: Icon(
                  _vpc!.value.isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  color: Colors.white, size: 26),
                onPressed: () => setState(() =>
                    _vpc!.value.isPlaying ? _vpc!.pause() : _vpc!.play()),
              ),
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 26),
              onPressed: _toggleFull),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => setState(() { _vpc?.pause(); _playing = null; })),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildFullscreen() => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(children: [
      Center(child: _vpc != null && _vpc!.value.isInitialized
          ? AspectRatio(aspectRatio: _vpc!.value.aspectRatio, child: VideoPlayer(_vpc!))
          : const CircularProgressIndicator(color: Colors.white)),
      Positioned(top: 20, left: 0, right: 0,
        child: Row(children: [
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 30),
            onPressed: _toggleFull),
          Expanded(child: Text(_playing?.name ?? '',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
          if (_vpc != null)
            IconButton(
              icon: Icon(
                _vpc!.value.isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                color: Colors.white, size: 30),
              onPressed: () => setState(() =>
                  _vpc!.value.isPlaying ? _vpc!.pause() : _vpc!.play())),
          const SizedBox(width: 16),
        ]),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
// RADIO SCREEN
// ══════════════════════════════════════════════════════════════
class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});
  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final _player = AudioPlayer();
  RadioStation? _playing;
  bool _loading = false;
  double _vol = 1.0;

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _play(RadioStation st) async {
    if (_playing?.name == st.name) {
      await _player.stop();
      setState(() => _playing = null);
      return;
    }
    setState(() { _loading = true; _playing = st; });
    try {
      await _player.stop();
      await _player.play(UrlSource(st.streamUrl));
      setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🎵 الراديو')),
    body: SafeArea(
      top: false,
      child: Column(children: [
        if (_playing != null) Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_playing!.colorObj, _playing!.colorObj.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Text(_playing!.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_playing!.name,
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text(_loading ? 'جاري التحميل...' : '▶️ يعزف الآن',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
            ])),
            Slider(
              value: _vol, min: 0, max: 1,
              activeColor: Colors.white, inactiveColor: Colors.white30,
              onChanged: (v) { setState(() => _vol = v); _player.setVolume(v); },
            ),
          ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          itemCount: AppConfig.radios.length,
          itemBuilder: (c, i) {
            final st  = AppConfig.radios[i];
            final isP = _playing?.name == st.name;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isP ? st.colorObj.withOpacity(0.08) : null,
              child: ListTile(
                leading: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: st.colorObj.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(st.emoji, style: const TextStyle(fontSize: 24))),
                ),
                title: Text(st.name,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, color: isP ? st.colorObj : null)),
                subtitle: Text(st.genre,
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                trailing: Icon(
                  isP ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
                  color: st.colorObj, size: 32),
                onTap: () => _play(st),
              ),
            );
          },
        )),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// JOKES SCREEN
// ══════════════════════════════════════════════════════════════
class JokesScreen extends StatefulWidget {
  const JokesScreen({super.key});
  @override
  State<JokesScreen> createState() => _JokesScreenState();
}

class _JokesScreenState extends State<JokesScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _setup = '', _punchline = '';
  bool _revealed = false, _loading = false;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _nextLocal(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _nextLocal() {
    final (s, p) = JokeService.getLocal();
    setState(() { _setup = s; _punchline = p; _revealed = false; });
  }

  Future<void> _nextOnline() async {
    setState(() { _loading = true; _revealed = false; _setup = ''; _punchline = ''; });
    final r = await JokeService.fetchOnline();
    setState(() {
      _loading = false;
      if (r != null) { _setup = r.$1; _punchline = r.$2; }
      else { _setup = 'تعذّر التحميل 😕'; _punchline = 'تحقق من الاتصال'; }
    });
  }

  Widget _jokeCard(VoidCallback onNext, String btnLabel) {
    final pr = AppConfig.colorPrimary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(children: [
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          const Text('😄', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(_loading ? '...' : (_setup.isEmpty ? 'اضغط للحصول على نكتة' : _setup),
              style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700, height: 1.6),
              textAlign: TextAlign.center),
          if (_revealed && _punchline.isNotEmpty) ...[
            const Divider(height: 32),
            Text(_punchline,
                style: GoogleFonts.cairo(
                    fontSize: 16, color: pr, fontWeight: FontWeight.w700, height: 1.6),
                textAlign: TextAlign.center),
          ],
        ]))),
        const SizedBox(height: 20),
        if (!_revealed && !_loading && _setup.isNotEmpty)
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => setState(() => _revealed = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.colorAccent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('اكشف الإجابة 👁️',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _loading ? null : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: pr, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text(btnLabel, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pr = AppConfig.colorPrimary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('😄 نكت'),
        bottom: TabBar(
          controller: _tab, indicatorColor: pr, labelColor: pr,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'محلية 🇹🇳'), Tab(text: 'من الإنترنت 🌐')],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tab,
          children: [
            _jokeCard(_nextLocal,  'نكتة أخرى 😄'),
            _jokeCard(_nextOnline, 'نكتة أخرى 🌐'),
          ],
        ),
      ),
    );
  }
}
