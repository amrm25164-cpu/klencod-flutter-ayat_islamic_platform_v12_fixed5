import 'package:flutter/material.dart';
import '../services/assistant_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _service = AssistantService();
  final List<_ChatMessage> _messages = [const _ChatMessage(false, 'أهلاً بك في رفيق آيات. أستطيع مساعدتك في فهم الموضوعات الإسلامية وتوجيهك للمصادر، لكن لا أُصدر فتاوى ولا أختلق مراجع. تحقق من النصوص والأحكام من مصادرها الأصلية.')];
  bool _loading = false;
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.length < 3 || _loading) return;
    setState(() { _messages.add(_ChatMessage(true, question)); _loading = true; });
    _controller.clear();
    try {
      final reply = await _service.ask(question);
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(false, '${reply.answer}\n\n${reply.label}${reply.sources.isEmpty ? '' : '\nالمصادر: ${reply.sources.join('، ')}'}${reply.requiresVerification ? '\nيرجى مراجعة المصادر الأصلية قبل الاعتماد على المعلومات.' : ''}')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add(const _ChatMessage(false, 'لم أتمكن من الاتصال بالمساعد. تأكد من إعداد خادم آيات ورمز التطبيق ومفتاح مزود الذكاء الاصطناعي على الخادم.')));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('رفيق آيات الذكي')),
    body: Column(children: [
      Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(12, 8, 12, 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF102820), borderRadius: BorderRadius.circular(14)), child: const Text('المساعد أداة معلوماتية. لا تعتمد عليه وحده في الفتوى أو التحقق من صحة حديث. أي إجابة مولّدة يجب مراجعتها.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white70))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(14), itemCount: _messages.length, itemBuilder: (context, i) { final m = _messages[i]; return Align(alignment: m.user ? Alignment.centerLeft : Alignment.centerRight, child: Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(14), constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .86), decoration: BoxDecoration(color: m.user ? const Color(0xFF075B43) : const Color(0xFF172D25), borderRadius: BorderRadius.circular(16)), child: Text(m.text, textDirection: TextDirection.rtl, style: const TextStyle(height: 1.7)))); })),
      if (_loading) const LinearProgressIndicator(),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(children: [Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, textDirection: TextDirection.rtl, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'اكتب سؤالك...', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))), const SizedBox(width: 8), IconButton.filled(onPressed: _loading ? null : _send, icon: const Icon(Icons.send))]))),
    ]),
  );
}

class _ChatMessage { final bool user; final String text; const _ChatMessage(this.user, this.text); }
