import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/quran_search_service.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final _controller = TextEditingController();
  final _service = QuranSearchService();
  List<QuranSearchResult> _results = [];
  List<Map<String, dynamic>> _saved = [];
  bool _loading = false;
  bool _showSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('ayat_saved_verses') ?? [];
    if (!mounted) return;
    setState(() {
      _saved = raw.map((value) {
        try {
          return Map<String, dynamic>.from(jsonDecode(value) as Map);
        } catch (_) {
          return <String, dynamic>{};
        }
      }).where((item) => item.isNotEmpty).toList();
    });
  }

  Future<void> _search([String? value]) async {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) {
      setState(() => _error = 'اكتب كلمة أو عبارة من الآية للبحث');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _showSaved = false;
      _results = [];
    });
    try {
      final results = await _service.search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'تعذر الاتصال بخدمة البحث. تحقق من الإنترنت ثم حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _asMap(QuranSearchResult item) => {
        'number': item.number,
        'numberInSurah': item.numberInSurah,
        'surahNumber': item.surahNumber,
        'surahName': item.surahName,
        'text': item.text,
      };

  Future<void> _toggleSaved(QuranSearchResult item) async {
    final map = _asMap(item);
    final key = '${item.surahNumber}:${item.numberInSurah}';
    final exists = _saved.any((e) => '${e['surahNumber']}:${e['numberInSurah']}' == key);
    setState(() {
      if (exists) {
        _saved.removeWhere((e) => '${e['surahNumber']}:${e['numberInSurah']}' == key);
      } else {
        _saved.insert(0, map);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ayat_saved_verses', _saved.map(jsonEncode).toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(exists ? 'تمت إزالة الآية من المحفوظات' : 'تم حفظ الآية على جهازك'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  bool _isSaved(QuranSearchResult item) => _saved.any((e) =>
      e['surahNumber'] == item.surahNumber && e['numberInSurah'] == item.numberInSurah);

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ نص الآية')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث في القرآن الكريم')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(children: [
            TextField(
              controller: _controller,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'ابحث بكلمة من القرآن الكريم',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'مسح',
                  onPressed: () {
                    _controller.clear();
                    setState(() { _results = []; _error = null; });
                  },
                  icon: const Icon(Icons.close),
                ),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: _loading ? null : () => _search(),
                icon: const Icon(Icons.search), label: const Text('ابحث'),
              )),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() { _showSaved = true; _error = null; }),
                icon: const Icon(Icons.bookmark_outline), label: Text('المحفوظات (${_saved.length})'),
              ),
            ]),
          ]),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    if (_showSaved) {
      if (_saved.isEmpty) return _empty('لا توجد آيات محفوظة بعد', Icons.bookmark_border);
      return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _saved.length,
        itemBuilder: (context, index) {
          final item = _saved[index];
          return _savedCard(item);
        },
      );
    }
    if (_error != null) return _empty(_error!, Icons.info_outline);
    if (_loading) return _empty('جاري البحث في نص القرآن الكريم…', Icons.manage_search);
    if (_results.isEmpty) return _empty('اكتب كلمة أو عبارة قرآنية لعرض الآيات المطابقة', Icons.menu_book_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _results.length,
      itemBuilder: (context, index) => _resultCard(_results[index]),
    );
  }

  Widget _empty(String message, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: const Color(0xFFD6B56D)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.7)),
      ]),
    ),
  );

  Future<void> _showTafsir(QuranSearchResult item) async {
    if (item.number < 1) return;
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF102820),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _AyahTafsirSheet(
        item: item,
        service: _service,
        onCopy: () => _copy(item.text),
      ),
    );
  }

  Widget _resultCard(QuranSearchResult item) {
    final saved = _isSaved(item);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(item.reference, style: const TextStyle(color: Color(0xFFD6B56D), fontWeight: FontWeight.bold))),
            IconButton(tooltip: 'تفسير مختصر', onPressed: () => _showTafsir(item), icon: const Icon(Icons.auto_stories_outlined, size: 20)),
            IconButton(tooltip: 'نسخ الآية', onPressed: () => _copy(item.text), icon: const Icon(Icons.copy_outlined, size: 20)),
            IconButton(tooltip: saved ? 'إزالة من المحفوظات' : 'حفظ الآية', onPressed: () => _toggleSaved(item), icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFD6B56D))),
          ]),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showTafsir(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(item.text, textDirection: TextDirection.rtl, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'KFGQPCUthmanic', fontSize: 25, height: 2.0)),
            ),
          ),
          const SizedBox(height: 8),
          Text('رقم السورة: ${item.surahNumber}  •  رقم الآية: ${item.numberInSurah}',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _savedCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('${item['surahName'] ?? 'سورة'} • الآية ${item['numberInSurah'] ?? ''}',
              style: const TextStyle(color: Color(0xFFD6B56D), fontWeight: FontWeight.bold))),
            IconButton(tooltip: 'عرض التفسير', onPressed: () {
              final savedAyah = QuranSearchResult(
                number: (item['number'] as num?)?.toInt() ?? 0,
                numberInSurah: (item['numberInSurah'] as num?)?.toInt() ?? 0,
                surahNumber: (item['surahNumber'] as num?)?.toInt() ?? 1,
                surahName: item['surahName'] as String? ?? 'سورة',
                text: item['text'] as String? ?? '',
                edition: 'quran-uthmani',
              );
              _showTafsir(savedAyah);
            }, icon: const Icon(Icons.auto_stories_outlined)),
            IconButton(onPressed: () async {
              setState(() => _saved.remove(item));
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList('ayat_saved_verses', _saved.map(jsonEncode).toList());
            }, icon: const Icon(Icons.delete_outline)),
          ]),
          Text(item['text'] as String? ?? '', textDirection: TextDirection.rtl,
            textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'KFGQPCUthmanic', fontSize: 24, height: 2)),
        ]),
      ),
    );
  }
}


class _AyahTafsirSheet extends StatefulWidget {
  final QuranSearchResult item;
  final QuranSearchService service;
  final VoidCallback onCopy;
  const _AyahTafsirSheet({required this.item, required this.service, required this.onCopy});

  @override
  State<_AyahTafsirSheet> createState() => _AyahTafsirSheetState();
}

class _AyahTafsirSheetState extends State<_AyahTafsirSheet> {
  String? _tafsir;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await widget.service.fetchAyahEdition(widget.item.number, 'ar.muyassar');
      if (!mounted) return;
      setState(() { _tafsir = text; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'تعذر تحميل التفسير. تحقق من الإنترنت وحاول مرة أخرى.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Text('${item.surahName} • الآية ${item.numberInSurah}', textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD6B56D), fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Text(item.text, textDirection: TextDirection.rtl, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'KFGQPCUthmanic', fontSize: 25, height: 2)),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const Text('التفسير الميسّر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_error != null) Column(children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent)),
              TextButton.icon(onPressed: () { setState(() { _loading = true; _error = null; }); _load(); }, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
            ])
            else Text(_tafsir ?? 'لا يوجد نص متاح.', textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 16, height: 1.9)),
            const SizedBox(height: 12),
            const Text('المصدر: AlQuran Cloud – إصدار ar.muyassar. هذا شرح موجز وليس جزءاً من نص القرآن الكريم.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.6)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: widget.onCopy, icon: const Icon(Icons.copy), label: const Text('نسخ نص الآية')),
          ]),
        ),
      ),
    );
  }
}
