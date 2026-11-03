import 'package:flutter/material.dart';
import '../services/tafsir_service.dart';

class TafsirScreen extends StatefulWidget {
  const TafsirScreen({super.key});

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  final _service = TafsirService();
  final _ayahController = TextEditingController(text: '1');
  final _surahController = TextEditingController(text: '1');
  List<QuranEdition> _tafsirs = const [];
  List<QuranEdition> _translations = const [];
  String? _tafsirId;
  String? _translationId;
  AyahStudyResult? _arabic;
  String? _tafsirText;
  String? _translationText;
  bool _loadingEditions = true;
  bool _loadingAyah = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEditions();
  }

  @override
  void dispose() {
    _ayahController.dispose();
    _surahController.dispose();
    super.dispose();
  }

  Future<void> _loadEditions() async {
    try {
      final results = await Future.wait([
        _service.getEditions('tafsir', language: 'ar'),
        _service.getEditions('translation', language: 'en'),
      ]);
      if (!mounted) return;
      setState(() {
        _tafsirs = results[0];
        _translations = results[1];
        _tafsirId = _pickDefault(_tafsirs, const ['ar.muyassar', 'ar.jalalayn']);
        _translationId = _pickDefault(_translations, const ['en.sahih', 'en.pickthall']);
        _loadingEditions = false;
      });
      await _loadAyah();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingEditions = false;
        _error = 'تعذر تحميل قائمة التفاسير والترجمات. تحقق من اتصال الإنترنت.';
      });
    }
  }

  String? _pickDefault(List<QuranEdition> editions, List<String> preferred) {
    for (final id in preferred) {
      if (editions.any((e) => e.identifier == id)) return id;
    }
    return editions.isEmpty ? null : editions.first.identifier;
  }

  Future<void> _loadAyah() async {
    final surah = int.tryParse(_surahController.text.trim());
    final ayah = int.tryParse(_ayahController.text.trim());
    if (surah == null || surah < 1 || surah > 114 || ayah == null || ayah < 1) {
      setState(() => _error = 'أدخل رقم سورة من 1 إلى 114 ورقم آية صحيح.');
      return;
    }
    if (_tafsirId == null && _translationId == null) {
      setState(() => _error = 'لا توجد مصادر متاحة حالياً.');
      return;
    }
    setState(() {
      _loadingAyah = true;
      _error = null;
      _arabic = null;
      _tafsirText = null;
      _translationText = null;
    });
    try {
      final arabicFuture = _service.getAyah(surah, ayah, 'quran-uthmani');
      final tafsirFuture = _tafsirId == null
          ? Future<AyahStudyResult?>.value(null)
          : _service.getAyah(surah, ayah, _tafsirId!).then<AyahStudyResult?>((v) => v);
      final translationFuture = _translationId == null
          ? Future<AyahStudyResult?>.value(null)
          : _service.getAyah(surah, ayah, _translationId!).then<AyahStudyResult?>((v) => v);
      final values = await Future.wait<Object?>([arabicFuture, tafsirFuture, translationFuture]);
      if (!mounted) return;
      setState(() {
        _arabic = values[0] as AyahStudyResult;
        _tafsirText = (values[1] as AyahStudyResult?)?.text;
        _translationText = (values[2] as AyahStudyResult?)?.text;
        _loadingAyah = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAyah = false;
        _error = 'تعذر جلب الآية أو أحد المصادر المختارة. جرّب مصدراً آخر أو تحقق من رقم الآية.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('التفسير والترجمات')),
        body: _loadingEditions
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('اختر موضع الآية والمصادر', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _surahController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رقم السورة', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _ayahController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رقم الآية', border: OutlineInputBorder()))),
                  ]),
                  const SizedBox(height: 12),
                  _editionDropdown('التفسير العربي', _tafsirs, _tafsirId, (value) => setState(() => _tafsirId = value)),
                  const SizedBox(height: 10),
                  _editionDropdown('الترجمة الإنجليزية', _translations, _translationId, (value) => setState(() => _translationId = value)),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _loadingAyah ? null : _loadAyah, icon: const Icon(Icons.menu_book), label: const Text('اعرض الآية')),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
                  if (_loadingAyah) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                  if (_arabic != null) ...[
                    const SizedBox(height: 18),
                    _section('نص الآية', _arabic!.text, arabic: true),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('${_arabic!.surahName} • الآية ${_arabic!.numberInSurah} • صفحة ${_arabic!.page}', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.secondary))),
                    if (_tafsirText != null) _section('التفسير — ${_tafsirs.firstWhere((e) => e.identifier == _tafsirId).displayName}', _tafsirText!),
                    if (_translationText != null) _section('الترجمة — ${_translations.firstWhere((e) => e.identifier == _translationId).displayName}', _translationText!),
                    const Padding(padding: EdgeInsets.only(top: 12), child: Text('للتدبر والفهم: راجع كتب التفسير المعتمدة وأقوال أهل العلم، فقد تختلف الترجمات في التعبير.', style: TextStyle(fontSize: 12, color: Colors.white60))),
                  ],
                ],
              ),
      );

  Widget _editionDropdown(String label, List<QuranEdition> editions, String? selected, ValueChanged<String?> onChanged) {
    if (editions.isEmpty) return Card(child: ListTile(title: Text(label), subtitle: const Text('لا توجد مصادر متاحة من الخدمة حالياً.')));
    final validSelected = editions.any((e) => e.identifier == selected) ? selected : editions.first.identifier;
    return DropdownButtonFormField<String>(
      value: validSelected,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: editions.map((e) => DropdownMenuItem(value: e.identifier, child: Text(e.displayName, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _section(String title, String body, {bool arabic = false}) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SelectableText(body, textDirection: arabic ? TextDirection.rtl : TextDirection.ltr, textAlign: arabic ? TextAlign.center : TextAlign.start, style: TextStyle(fontSize: arabic ? 26 : 16, height: arabic ? 2 : 1.7, fontFamily: arabic ? 'KFGQPCUthmanic' : null)),
          ]),
        ),
      );
}
