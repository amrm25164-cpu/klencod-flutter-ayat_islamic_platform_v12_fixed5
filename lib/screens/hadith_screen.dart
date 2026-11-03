import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/hadith_service.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});
  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final _controller = TextEditingController();
  final _service = HadithService();
  List<HadithRecord> _items = [];
  bool _loading = false;
  String? _message;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) { setState(() => _message = 'اكتب كلمة أو جزءًا من الحديث للبحث'); return; }
    setState(() { _loading = true; _message = null; _items = []; });
    try {
      final result = await _service.search(q);
      if (!mounted) return;
      setState(() { _items = result; if (result.isEmpty) _message = 'لم يعثر الخادم على نتائج مطابقة.'; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = !_service.isConfigured
        ? 'بحث الحديث يحتاج خادمًا وسيطًا آمنًا. لم يتم تضمين مفاتيح أي مزوّد داخل التطبيق.'
        : 'تعذر الاتصال بخادم الحديث. تحقق من إعداد الخادم والإنترنت ثم أعد المحاولة.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الحديث الشريف')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF102820), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD6B56D).withOpacity(.35))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('بحث موثّق في السنة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8), Text('تعرض النتائج نص الحديث ومصدره ورقمه ودرجة الحكم عند توفرها. لا تُنشأ درجات أو مراجع تلقائيًا.'),
      ])),
      const SizedBox(height: 14),
      TextField(controller: _controller, textDirection: TextDirection.rtl, onSubmitted: (_) => _search(), decoration: InputDecoration(hintText: 'ابحث في نص الحديث...', filled: true, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: _loading ? null : _search, icon: const Icon(Icons.manage_search), label: const Text('بحث')),
      if (_loading) const Padding(padding: EdgeInsets.only(top: 18), child: LinearProgressIndicator()),
      if (_message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(children: [const Icon(Icons.info_outline, size: 42, color: Color(0xFFD6B56D)), const SizedBox(height: 10), Text(_message!, textAlign: TextAlign.center, style: const TextStyle(height: 1.7, color: Colors.white70)), if (!_service.isConfigured) const Padding(padding: EdgeInsets.only(top: 8), child: Text('الإعداد: شغّل التطبيق مع --dart-define=AYAT_API_BASE_URL=https://your-domain.example/api', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white38)))])),
      ..._items.map((h) => Card(margin: const EdgeInsets.only(top: 10), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(h.source, style: const TextStyle(color: Color(0xFFD6B56D), fontWeight: FontWeight.bold)), if (h.reference.isNotEmpty) Text('المرجع: ${h.reference}', style: const TextStyle(color: Colors.white60, fontSize: 12)), const SizedBox(height: 12), Text(h.text, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 19, height: 1.9)), if (h.narrator != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('الراوي: ${h.narrator}')), const SizedBox(height: 8), Text('الدرجة: ${h.grade}', style: const TextStyle(color: Colors.white70)), if (h.url != null && Uri.tryParse(h.url!)?.hasScheme == true) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: h.url!)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط المصدر'))); }, icon: const Icon(Icons.link), label: const Text('رابط المصدر متاح')))])))),
    ]),
  );
}
