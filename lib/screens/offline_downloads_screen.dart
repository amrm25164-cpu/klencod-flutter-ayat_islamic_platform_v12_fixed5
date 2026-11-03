import 'dart:io';
import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/offline_download_service.dart';
import '../services/quran_service.dart';

class OfflineDownloadsScreen extends StatefulWidget {
  const OfflineDownloadsScreen({super.key});
  @override
  State<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<OfflineDownloadsScreen> {
  final _offline = OfflineDownloadService();
  final _quran = QuranService();
  List<SurahInfo> _surahs = [];
  List<Reciter> _reciters = [];
  List<OfflineDownloadItem> _items = [];
  int _surah = 1;
  Reciter? _reciter;
  bool _loading = true;
  bool _busy = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_quran.getSurahs(), _quran.getReciters(), _offline.list()]);
      if (!mounted) return;
      setState(() {
        _surahs = results[0] as List<SurahInfo>;
        _reciters = results[1] as List<Reciter>;
        _items = results[2] as List<OfflineDownloadItem>;
        _reciter = _reciters.isEmpty ? null : _reciters.first;
        _loading = false;
      });
    } catch (e) { if (mounted) setState(() { _loading = false; _error = 'تعذر تحميل قائمة السور والقراء. تحقق من الإنترنت ثم أعد المحاولة.'; }); }
  }

  String _size(int bytes) => bytes < 1024 * 1024 ? '${(bytes / 1024).toStringAsFixed(0)} KB' : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  Future<void> _download() async {
    if (_reciter == null || _surahs.isEmpty) return;
    setState(() { _busy = true; _progress = 0; _error = null; });
    try {
      await _offline.downloadSurah(_surahs.firstWhere((s) => s.number == _surah), _reciter!, onProgress: (received, total) { if (mounted && total > 0) setState(() => _progress = received / total); });
      final items = await _offline.list();
      if (mounted) setState(() => _items = items);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تنزيل السورة والنص بنجاح')));
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _delete(OfflineDownloadItem item) async {
    await _offline.delete(item);
    if (mounted) setState(() => _items.removeWhere((x) => x.surah == item.surah));
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<int>(0, (sum, item) => sum + item.bytes);
    return Scaffold(
      appBar: AppBar(title: const Text('التنزيلات دون إنترنت')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF102820), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD6B56D).withOpacity(.4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('نزّل القرآن للاستماع والقراءة دون اتصال', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), const Text('يُحفظ نص السورة وملف التلاوة داخل مساحة التطبيق الخاصة. التنزيل يحتاج إنترنت ومساحة كافية.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(value: _surah, isExpanded: true, decoration: const InputDecoration(labelText: 'السورة'), items: _surahs.map((s) => DropdownMenuItem(value: s.number, child: Text('${s.number}. ${s.name}'))).toList(), onChanged: _busy ? null : (v) { if (v != null) setState(() => _surah = v); }),
          const SizedBox(height: 12),
          DropdownButtonFormField<Reciter>(value: _reciter, isExpanded: true, decoration: const InputDecoration(labelText: 'القارئ'), items: _reciters.map((r) => DropdownMenuItem(value: r, child: Text(r.name, overflow: TextOverflow.ellipsis))).toList(), onChanged: _busy ? null : (v) => setState(() => _reciter = v)),
          const SizedBox(height: 16),
          if (_busy) LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy || _reciter == null || _surahs.isEmpty ? null : _download, icon: Icon(_busy ? Icons.downloading : Icons.download), label: Text(_busy ? 'جارٍ التنزيل… ${(_progress * 100).toStringAsFixed(0)}%' : 'تنزيل السورة'))),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
        ])),
        const SizedBox(height: 22),
        Row(children: [const Expanded(child: Text('المحتوى المحفوظ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))), Text('${_items.length} سورة • ${_size(total)}', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
        const SizedBox(height: 10),
        if (_items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد تنزيلات بعد. اختر سورة وقارئًا لبدء التنزيل.'))),
        ..._items.map((item) => Card(child: ListTile(leading: const Icon(Icons.offline_pin, color: Color(0xFFD6B56D)), title: Text('${item.surah}. ${item.surahName}'), subtitle: Text('${item.reciterName} • ${_size(item.bytes)}\n${File(item.audioPath).existsSync() ? 'ملف الصوت محفوظ' : 'ملف الصوت غير موجود'}'), isThreeLine: true, trailing: IconButton(tooltip: 'حذف التنزيل', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(item))))),
        const SizedBox(height: 12),
        const Text('ملاحظة: هذه المرحلة تحفظ الملفات محليًا وتدير حذفها. تشغيل الصوت أو فتح النص المحفوظ من المشغل والمصحف يحتاج تفعيل مسار القراءة دون اتصال في المرحلة التالية.', style: TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }
}
