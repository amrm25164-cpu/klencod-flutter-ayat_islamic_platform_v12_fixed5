import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';
import 'ayah_sync_screen.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});
  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  final _service = QuranService();
  final _player = AudioPlayer();
  late Future<List<Reciter>> _future;
  StreamSubscription<PlayerState>? _stateSubscription;
  Reciter? _selected;
  int _surah = 1;
  bool _repeatOne = false;
  bool _loadingTrack = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _future = _service.getReciters();
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {});
      if (state.processingState == ProcessingState.completed && !_repeatOne) {
        _playAdjacent(1);
      }
    });
  }

  bool _supportsSurah(Reciter reciter, int surah) {
    final ids = reciter.surahList
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
    return ids.isEmpty || ids.contains(surah);
  }

  Future<void> _play(Reciter reciter, {int? surah}) async {
    final targetSurah = surah ?? _surah;
    if (!_supportsSurah(reciter, targetSurah)) {
      _message('القارئ لا يوفّر هذه السورة في الرواية المختارة.');
      return;
    }
    setState(() {
      _selected = reciter;
      _surah = targetSurah;
      _loadingTrack = true;
    });
    try {
      await _player.setUrl(reciter.audioUrl(targetSurah));
      await _player.setSpeed(_speed);
      await _player.setLoopMode(_repeatOne ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (_) {
      _message('تعذر تشغيل التلاوة. تحقق من اتصال الإنترنت أو جرّب قارئاً آخر.');
    } finally {
      if (mounted) setState(() => _loadingTrack = false);
    }
  }

  Future<void> _playAdjacent(int delta) async {
    final reciter = _selected;
    if (reciter == null) return;
    var next = _surah + delta;
    for (var attempts = 0; attempts < 114; attempts++) {
      if (next > 114) next = 1;
      if (next < 1) next = 114;
      if (_supportsSurah(reciter, next)) {
        await _play(reciter, surah: next);
        return;
      }
      next += delta;
    }
    _message('لا توجد سور أخرى متاحة لهذا القارئ.');
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours > 0 ? '${value.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('مكتبة القراء'),
      actions: [IconButton(tooltip: 'مزامنة الآيات مع التلاوة', icon: const Icon(Icons.sync), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AyahSyncScreen())))],
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: DropdownButtonFormField<int>(
          value: _surah,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'اختر السورة', border: OutlineInputBorder()),
          items: List.generate(114, (i) => DropdownMenuItem(
            value: i + 1, child: Text('السورة رقم ${i + 1}'))),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _surah = v);
            if (_selected != null) _play(_selected!, surah: v);
          },
        ),
      ),
      Expanded(child: FutureBuilder<List<Reciter>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: TextButton(
              onPressed: () => setState(() => _future = _service.getReciters()),
              child: const Text('تعذر تحميل القراء — إعادة المحاولة')));
          }
          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final reciter = snapshot.data![index];
              final active = _selected?.id == reciter.id;
              return ListTile(
                leading: CircleAvatar(child: Icon(active ? Icons.graphic_eq : Icons.person_outline)),
                title: Text(reciter.name),
                subtitle: Text(reciter.moshafName),
                trailing: IconButton(
                  tooltip: active && _player.playing ? 'إيقاف مؤقت' : 'تشغيل',
                  icon: Icon(active && _player.playing ? Icons.pause_circle : Icons.play_circle,
                    size: 34),
                  onPressed: () async {
                    if (active && _player.playing) {
                      await _player.pause();
                    } else if (active && _player.processingState != ProcessingState.idle) {
                      await _player.play();
                    } else {
                      await _play(reciter);
                    }
                  },
                ),
                onTap: () => _play(reciter),
              );
            },
          );
        },
      )),
      _buildPlayerPanel(),
    ]),
  );

  Widget _buildPlayerPanel() {
    final active = _selected;
    if (active == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('اختر قارئاً لبدء الاستماع', style: TextStyle(color: Colors.grey)),
      );
    }
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.headphones),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(active.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('السورة رقم $_surah', style: Theme.of(context).textTheme.bodySmall),
              ])),
              if (_loadingTrack) const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _player.duration ?? Duration.zero;
                final max = duration.inMilliseconds.toDouble();
                final value = position.inMilliseconds.toDouble().clamp(0.0, max > 0 ? max : 1.0).toDouble();
                return Column(children: [
                  Slider(
                    value: value,
                    max: max > 0 ? max : 1,
                    onChanged: max <= 0 ? null : (v) => _player.seek(Duration(milliseconds: v.round())),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_time(position), style: Theme.of(context).textTheme.labelSmall),
                    Text(_time(duration), style: Theme.of(context).textTheme.labelSmall),
                  ]),
                ]);
              },
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(tooltip: 'السورة السابقة', onPressed: () => _playAdjacent(-1),
                icon: const Icon(Icons.skip_previous, size: 30)),
              IconButton(
                tooltip: _player.playing ? 'إيقاف مؤقت' : 'استكمال',
                onPressed: _loadingTrack ? null : () async {
                  if (_player.playing) { await _player.pause(); }
                  else if (_player.processingState == ProcessingState.idle) { await _play(active); }
                  else { await _player.play(); }
                },
                icon: Icon(_player.playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 48),
              ),
              IconButton(tooltip: 'السورة التالية', onPressed: () => _playAdjacent(1),
                icon: const Icon(Icons.skip_next, size: 30)),
              IconButton(
                tooltip: _repeatOne ? 'إلغاء تكرار السورة' : 'تكرار السورة',
                onPressed: () async {
                  setState(() => _repeatOne = !_repeatOne);
                  await _player.setLoopMode(_repeatOne ? LoopMode.one : LoopMode.off);
                },
                color: _repeatOne ? Theme.of(context).colorScheme.primary : null,
                icon: const Icon(Icons.repeat_one),
              ),
            ]),
            Row(children: [
              const Icon(Icons.speed, size: 18),
              const SizedBox(width: 8),
              Text('${_speed.toStringAsFixed(2)}x'),
              Expanded(child: Slider(
                min: 0.75, max: 1.5, divisions: 6, value: _speed,
                onChanged: (value) async {
                  setState(() => _speed = value);
                  await _player.setSpeed(value);
                },
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
