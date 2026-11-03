import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';
import 'mushaf_screen.dart';
import 'reading_screen.dart';

class SurahIndexScreen extends StatefulWidget {
  const SurahIndexScreen({super.key});

  @override
  State<SurahIndexScreen> createState() => _SurahIndexScreenState();
}

class _SurahIndexScreenState extends State<SurahIndexScreen> {
  final _service = QuranService();
  final _search = TextEditingController();
  late Future<List<SurahInfo>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.getSurahs();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openSurah(SurahInfo surah, {required bool readingMode}) async {
    try {
      if (readingMode) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReadingScreen(initialSurah: surah.number)));
      } else {
        final page = await _service.getSurahFirstPage(surah.number);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => MushafScreen(initialPage: page)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح السورة. تحقق من اتصال الإنترنت.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('فهرس سور القرآن الكريم')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _search,
          textDirection: TextDirection.rtl,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            hintText: 'ابحث باسم السورة أو رقمها',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(child: FutureBuilder<List<SurahInfo>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('تعذر تحميل فهرس السور'),
              TextButton(onPressed: () => setState(() => _future = _service.getSurahs()), child: const Text('إعادة المحاولة')),
            ]));
          }
          final q = _query.toLowerCase();
          final items = snapshot.data!.where((s) => s.name.contains(_query) || s.number.toString() == q || s.englishName.toLowerCase().contains(q)).toList();
          if (items.isEmpty) return const Center(child: Text('لا توجد سورة مطابقة للبحث'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final surah = items[index];
              final isMeccan = surah.revelationType.toLowerCase() == 'meccan';
              return Card(child: ListTile(
                leading: Container(
                  width: 42, height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFD6B56D).withOpacity(.14), borderRadius: BorderRadius.circular(12)),
                  child: Text('${surah.number}', style: const TextStyle(color: Color(0xFFD6B56D), fontWeight: FontWeight.bold)),
                ),
                title: Text(surah.name, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                subtitle: Text('${isMeccan ? 'مكية' : 'مدنية'} • ${surah.numberOfAyahs} آية'),
                trailing: PopupMenuButton<String>(
                  tooltip: 'فتح السورة',
                  onSelected: (value) => _openSurah(surah, readingMode: value == 'reading'),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'mushaf', child: Text('فتح في المصحف')),
                    PopupMenuItem(value: 'reading', child: Text('قراءة الآيات')),
                  ],
                ),
                onTap: () => _openSurah(surah, readingMode: false),
              ));
            },
          );
        },
      )),
    ]),
  );
}
