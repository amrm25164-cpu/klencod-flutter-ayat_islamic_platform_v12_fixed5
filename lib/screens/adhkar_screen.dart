import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});
  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  int _count = 0;
  int _index = 0;
  bool _ready = false;
  static const adhkar = [
    ('سُبْحَانَ اللَّهِ', 33), ('الْحَمْدُ لِلَّهِ', 33),
    ('اللَّهُ أَكْبَرُ', 34), ('أَسْتَغْفِرُ اللَّهَ', 100),
    ('لَا إِلَهَ إِلَّا اللَّهُ', 100),
  ];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { _count = p.getInt('adhkar_count') ?? 0; _index = (p.getInt('adhkar_index') ?? 0).clamp(0, adhkar.length - 1).toInt(); _ready = true; });
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('adhkar_count', _count); await p.setInt('adhkar_index', _index);
  }
  void _increment() {
    setState(() { _count++; if (_count >= adhkar[_index].$2) { _count = 0; _index = (_index + 1) % adhkar.length; } });
    _save();
  }
  @override
  Widget build(BuildContext context) {
    final item = adhkar[_index];
    return Scaffold(appBar: AppBar(title: const Text('السبحة والأذكار')), body: !_ready ? const Center(child: CircularProgressIndicator()) : Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('الذكر الحالي'), const SizedBox(height: 20),
      Text(item.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, height: 1.8)),
      const SizedBox(height: 26), Text('$_count / ${item.$2}', style: TextStyle(fontSize: 34, color: Theme.of(context).colorScheme.secondary)),
      const SizedBox(height: 20), FilledButton(onPressed: _increment, style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(42)), child: const Icon(Icons.touch_app, size: 40)),
      TextButton(onPressed: () { setState(() => _count = 0); _save(); }, child: const Text('تصفير العداد')),
      TextButton(onPressed: () { setState(() { _count = 0; _index = 0; }); _save(); }, child: const Text('إعادة بدء سلسلة الأذكار')),
      const Text('يُحفظ تقدم السبحة محلياً على هذا الجهاز.', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]))));
  }
}
