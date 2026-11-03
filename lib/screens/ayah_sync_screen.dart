import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/quran_models.dart';
import '../services/ayah_sync_service.dart';
import '../services/quran_service.dart';

class AyahSyncScreen extends StatefulWidget {
  const AyahSyncScreen({super.key});
  @override
  State<AyahSyncScreen> createState() => _AyahSyncScreenState();
}

class _AyahSyncScreenState extends State<AyahSyncScreen> {
  final _sync = AyahSyncService();
  final _quran = QuranService();
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  List<QuranRecitation> _recitations = [];
  List<Ayah> _ayahs = [];
  List<AyahTiming> _timings = [];
  int _surah = 1;
  int? _recitationId;
  int? _activeAyah;
  bool _loading = true;
  bool _loadingAudio = false;
  String? _error;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.positionStream.listen(_updateActiveAyah);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final recitations = await _sync.getRecitations();
      if (!mounted) return;
      setState(() {
        _recitations = recitations;
        _recitationId = recitations.isNotEmpty ? recitations.first.id : null;
        _loading = false;
      });
      await _loadAyahs();
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'تعذر تحميل مصادر التلاوة: $e'; });
    }
  }

  Future<void> _loadAyahs() async {
    setState(() { _loadingAudio = true; _error = null; });
    try {
      final ayahs = await _quran.getSurah(_surah);
      if (!mounted) return;
      setState(() { _ayahs = ayahs; _activeAyah = null; _timings = []; });
      await _loadSynchronizedAudio(autoPlay: false);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحميل الآيات: $e');
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  Future<void> _loadSynchronizedAudio({bool autoPlay = true}) async {
    final id = _recitationId;
    if (id == null) return;
    setState(() { _loadingAudio = true; _error = null; });
    try {
      final chapter = await _sync.getChapter(id, _surah);
      await _player.setUrl(chapter.audioUrl);
      await _player.setSpeed(_speed);
      if (!mounted) return;
      setState(() => _timings = chapter.timings);
      if (autoPlay) await _player.play();
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تفعيل المزامنة: $e');
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  void _updateActiveAyah(Duration position) {
    final ms = position.inMilliseconds;
    AyahTiming? found;
    for (final timing in _timings) {
      if (ms >= timing.startMs && ms < timing.endMs) { found = timing; break; }
    }
    if (found != null && found.ayah != _activeAyah && mounted) {
      setState(() => _activeAyah = found!.ayah);
    }
  }

  Future<void> _seekAyah(int ayahNumber) async {
    final matches = _timings.where((t) => t.ayah == ayahNumber).toList();
    if (matches.isEmpty) return;
    await _player.seek(Duration(milliseconds: matches.first.startMs));
    if (!_player.playing) await _player.play();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('المزامنة التلقائية للآيات')),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            DropdownButtonFormField<int>(
              value: _surah,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'السورة', border: OutlineInputBorder()),
              items: List.generate(114, (i) => DropdownMenuItem(value: i + 1, child: Text('السورة رقم ${i + 1}'))),
              onChanged: (v) async { if (v == null) return; setState(() => _surah = v); await _loadAyahs(); },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _recitationId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'القارئ / مصدر التوقيت', border: OutlineInputBorder()),
              items: _recitations.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name}${r.style.isEmpty ? '' : ' — ${r.style}'}', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) async { if (v == null) return; setState(() => _recitationId = v); await _loadSynchronizedAudio(autoPlay: false); },
            ),
          ])),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
          if (_loadingAudio) const LinearProgressIndicator(),
          Expanded(child: _ayahs.isEmpty
            ? const Center(child: Text('لا توجد آيات للعرض'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: _ayahs.length,
                itemBuilder: (context, index) {
                  final ayah = _ayahs[index];
                  final active = ayah.numberInSurah == _activeAyah;
                  return Card(
                    color: active ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _seekAyah(ayah.numberInSurah),
                      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(ayah.text, textAlign: TextAlign.center, textDirection: TextDirection.rtl,
                          style: TextStyle(fontFamily: 'KFGQPCUthmanic', fontSize: 25, height: 2, color: active ? Theme.of(context).colorScheme.onPrimaryContainer : const Color(0xFFF2E6C9))),
                        Align(alignment: Alignment.centerLeft, child: Chip(avatar: Icon(active ? Icons.graphic_eq : Icons.play_arrow, size: 17), label: Text('الآية ${ayah.numberInSurah}'))),
                      ])),
                    ),
                  );
                },
              )),
          _playerPanel(),
        ]),
  );

  Widget _playerPanel() => Material(
    elevation: 8,
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: _timings.isEmpty ? null : () => _seekAyah((_activeAyah ?? 1) - 1), icon: const Icon(Icons.skip_previous)),
        StreamBuilder<PlayerState>(stream: _player.playerStateStream, builder: (context, snapshot) {
          final playing = snapshot.data?.playing ?? false;
          return IconButton(iconSize: 48, onPressed: _timings.isEmpty ? null : () async { if (playing) { await _player.pause(); } else { await _player.play(); } }, icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill));
        }),
        IconButton(onPressed: _timings.isEmpty ? null : () => _seekAyah((_activeAyah ?? 0) + 1), icon: const Icon(Icons.skip_next)),
      ]),
      StreamBuilder<Duration>(stream: _player.positionStream, builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _player.duration ?? Duration.zero;
        final max = duration.inMilliseconds.toDouble();
        final value = position.inMilliseconds.toDouble().clamp(0.0, max > 0 ? max : 1.0).toDouble();
        return Column(children: [
          Slider(value: value, max: max > 0 ? max : 1, onChanged: max <= 0 ? null : (v) => _player.seek(Duration(milliseconds: v.round()))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_format(position)), Text(_format(duration))]),
        ]);
      }),
      Row(children: [const Icon(Icons.speed, size: 18), Text(' ${_speed.toStringAsFixed(2)}x'), Expanded(child: Slider(min: .75, max: 1.5, divisions: 6, value: _speed, onChanged: (v) async { setState(() => _speed = v); await _player.setSpeed(v); }))]),
      Text(_timings.isEmpty ? 'اختر مصدر تلاوة يدعم توقيت الآيات' : 'المزامنة تعمل — الآية الحالية: ${_activeAyah ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
    ]))),
  );
}
