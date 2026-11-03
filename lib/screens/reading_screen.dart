import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';

class ReadingScreen extends StatefulWidget {
  final int initialSurah;
  const ReadingScreen({super.key, this.initialSurah = 1});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _service = QuranService();
  int _surah = 1;
  Future<List<Ayah>>? _future;

  @override
  void initState() {
    super.initState();
    _surah = widget.initialSurah.clamp(1, 114).toInt();
    _future = _service.getSurah(_surah);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('القراءة المتتابعة')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<int>(
          value: _surah,
          decoration: const InputDecoration(
            labelText: 'اختر رقم السورة',
            border: OutlineInputBorder()),
          items: List.generate(114, (i) => DropdownMenuItem(
            value: i + 1, child: Text('سورة رقم ${i + 1}'))),
          onChanged: (value) {
            if (value == null) return;
            setState(() { _surah = value; _future = _service.getSurah(value); });
          },
        ),
      ),
      Expanded(child: FutureBuilder<List<Ayah>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('تعذر تحميل السورة. تحقق من الإنترنت.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final ayah = snapshot.data![index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(ayah.text, textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 25, height: 2, color: Color(0xFFF2E6C9), fontFamily: 'KFGQPCUthmanic')),
                  Align(alignment: Alignment.centerLeft,
                    child: Chip(label: Text('الآية ${ayah.numberInSurah}'))),
                ]),
              );
            },
          );
        },
      )),
    ]),
  );
}
