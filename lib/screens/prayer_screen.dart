import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Map<String, dynamic>? _times;
  bool _loading = false;
  String _city = 'Alexandria';
  String? _error;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await Dio().get('https://api.aladhan.com/v1/timingsByCity', queryParameters: {'city': _city, 'country': 'Egypt', 'method': 5});
      final data = response.data['data']['timings'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _times = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر جلب المواقيت. تحقق من اتصال الإنترنت وحاول مرة أخرى.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    const names = {'Fajr':'الفجر','Sunrise':'الشروق','Dhuhr':'الظهر','Asr':'العصر','Maghrib':'المغرب','Isha':'العشاء'};
    return Scaffold(appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF0B654D), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مواقيت الصلاة حسب المدينة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _city, dropdownColor: const Color(0xFF102820), decoration: const InputDecoration(labelText: 'المدينة', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'Alexandria', child: Text('الإسكندرية')), DropdownMenuItem(value: 'Cairo', child: Text('القاهرة')), DropdownMenuItem(value: 'Giza', child: Text('الجيزة'))], onChanged: (v) { if (v != null) { _city = v; _load(); } }),
        ])),
        const SizedBox(height: 18),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
        if (_times != null) ...names.entries.map((e) => Card(child: ListTile(leading: const Icon(Icons.access_time, color: Color(0xFFD6B56D)), title: Text(e.value), trailing: Text((_times![e.key] ?? '--:--').toString().split(' ').first, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))),
        const SizedBox(height: 12),
        const Text('المواقيت محسوبة وفق طريقة الهيئة المصرية العامة للمساحة. قد تختلف بضع دقائق عن توقيت المسجد المحلي.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تحديث المواقيت')),
      ]));
  }
}
