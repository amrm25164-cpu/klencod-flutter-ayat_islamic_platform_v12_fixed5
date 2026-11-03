import 'package:flutter/material.dart';
import '../services/reading_goal_service.dart';

class ReadingGoalScreen extends StatefulWidget {
  const ReadingGoalScreen({super.key});
  @override
  State<ReadingGoalScreen> createState() => _ReadingGoalScreenState();
}

class _ReadingGoalScreenState extends State<ReadingGoalScreen> {
  final _service = ReadingGoalService();
  ReadingGoalSnapshot? _snapshot;
  bool _busy = true;

  @override
  void initState() { super.initState(); _refresh(); }
  Future<void> _refresh() async {
    final value = await _service.load();
    if (!mounted) return;
    setState(() { _snapshot = value; _busy = false; });
  }
  Future<void> _changeTarget(int value) async {
    final result = await _service.setTarget(value);
    if (mounted) setState(() => _snapshot = result);
  }
  Future<void> _add(int pages) async {
    final result = await _service.addPages(pages);
    if (mounted) setState(() => _snapshot = result);
  }

  @override
  Widget build(BuildContext context) {
    final s = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('وردي اليومي')),
      body: _busy || s == null ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(20), children: [
          Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [Color(0xFF075B43), Color(0xFF102820)]),
            border: Border.all(color: const Color(0xFFD6B56D).withOpacity(.4)),
          ), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('اجعل لك وردًا ثابتًا', style: TextStyle(color: Color(0xFFD6B56D), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${s.completedPages} / ${s.targetPages} صفحة', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: s.progress, minHeight: 12, backgroundColor: Colors.white12, color: const Color(0xFFD6B56D))),
            const SizedBox(height: 10),
            Text(s.isComplete ? 'ما شاء الله، أتممت ورد اليوم!' : 'متبقي ${s.targetPages > s.completedPages ? s.targetPages - s.completedPages : 0} صفحة لإتمام وردك', style: const TextStyle(color: Colors.white70)),
          ])),
          const SizedBox(height: 22),
          const Text('الهدف اليومي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [2, 4, 5, 10, 15, 20, 30].map((n) => ChoiceChip(label: Text('$n صفحة'), selected: s.targetPages == n, onSelected: (_) => _changeTarget(n))).toList()),
          const SizedBox(height: 22),
          const Text('تسجيل القراءة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [1, 2, 5, 10].map((n) => FilledButton.tonal(onPressed: () => _add(n), child: Text('إضافة $n صفحة'))).toList()),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: () async { final result = await _service.reset(); if (mounted) setState(() => _snapshot = result); }, icon: const Icon(Icons.restart_alt), label: const Text('إعادة ضبط إنجاز اليوم')),
          const SizedBox(height: 12),
          const Text('يُحفظ تقدمك على هذا الجهاز فقط. تسجيل الصفحات يدوي، ولا يتم احتسابها تلقائيًا من مدة فتح المصحف.', style: TextStyle(color: Colors.white60, height: 1.6, fontSize: 12)),
        ],
      ),
    );
  }
}
