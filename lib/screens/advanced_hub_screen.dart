import 'package:flutter/material.dart';
import 'quran_search_screen.dart';
import 'hadith_screen.dart';
import 'reading_goal_screen.dart';
import 'assistant_screen.dart';

class AdvancedHubScreen extends StatelessWidget {
  const AdvancedHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HubItem>[
      _HubItem('البحث في القرآن الكريم', 'ابحث بالكلمات والعبارات واعرض الآيات المطابقة واحفظها', Icons.search_rounded, 'مصدر النص: AlQuran Cloud'),
      _HubItem('الحديث الشريف', 'ابحث في دواوين السنة وتتبّع التخريج والدرجات', Icons.menu_book_rounded, 'HadithDB'),
      _HubItem('وردي اليومي', 'حدد هدفًا للقراءة وسجّل إنجازك اليومي', Icons.track_changes_rounded, 'حفظ محلي على الجهاز'),
      _HubItem('التفسير وعلوم القرآن', 'تفسير بالمصادر ومقارنة أقوال المفسرين', Icons.auto_stories_rounded, 'quran.ai • Tarteel'),
      _HubItem('البحث في المكتبة الشرعية', 'ابحث في كتب التراث واقرأ النصوص مع العزو', Icons.local_library_rounded, 'دلائل'),
      _HubItem('رفيق آيات الذكي', 'اسأل، استكشف، وتعلّم مع إظهار المصادر', Icons.psychology_alt_rounded, 'OpenAI'),
      _HubItem('الأدعية والأسماء الحسنى', 'أدعية موثقة ومعاني أسماء الله الحسنى', Icons.volunteer_activism_rounded, 'Muslim Expert'),
      _HubItem('دراسة القرآن التفاعلية', 'بحث الآيات والتلاوات والتفسير ومراجعة الحفظ', Icons.school_rounded, 'Tarteel • quran.ai'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('المركز الإسلامي')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [Color(0xFF075B43), Color(0xFF102820)], begin: Alignment.topRight, end: Alignment.bottomLeft),
            border: Border.all(color: const Color(0xFFD6B56D).withOpacity(.4)),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('العلم بالأثر والمصدر', style: TextStyle(color: Color(0xFFD6B56D), fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('مكتبتك للقرآن والسنة والبحث الشرعي', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('نعرض النصوص مع مراجعها، ونميّز بين النص المنقول والشرح والمحتوى المولّد بالذكاء الاصطناعي.'),
          ]),
        ),
        const SizedBox(height: 18),
        ...items.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: CircleAvatar(radius: 24, backgroundColor: const Color(0xFF0B8060).withOpacity(.2), child: Icon(item.icon, color: const Color(0xFFD6B56D))),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.subtitle), const SizedBox(height: 4), Text(item.source, style: const TextStyle(color: Color(0xFFD6B56D), fontSize: 11))]),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              if (item.title == 'البحث في القرآن الكريم') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranSearchScreen()));
              } else if (item.title == 'الحديث الشريف') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithScreen()));
              } else if (item.title == 'وردي اليومي') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingGoalScreen()));
              } else if (item.title == 'رفيق آيات الذكي') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => _FeatureInfoPage(item: item)));
              }
            },
          ),
        )),
        const SizedBox(height: 8),
        const Text('ملاحظة: ربط خدمات المصادر الخارجية يحتاج إعداد مفاتيح الوصول والاتفاقيات الخاصة بكل مزوّد. لا تُعرض هذه البطاقات على أنها اتصال مباشر قبل إتمام الربط واختباره.', style: TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }
}

class _HubItem {
  final String title, subtitle, source;
  final IconData icon;
  const _HubItem(this.title, this.subtitle, this.icon, this.source);
}

class _FeatureInfoPage extends StatelessWidget {
  final _HubItem item;
  const _FeatureInfoPage({required this.item});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(item.title)),
    body: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(item.icon, size: 54, color: const Color(0xFFD6B56D)),
      const SizedBox(height: 18),
      Text(item.title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10), Text(item.subtitle),
      const SizedBox(height: 22),
      const Text('سيعمل هذا القسم على عرض المادة الأصلية، واسم الكتاب أو الراوي، ورقم الحديث أو الآية، ورابط المصدر متى توفر. وسيتم فصل النتائج الموثقة عن ملخصات الذكاء الاصطناعي.'),
      const SizedBox(height: 18),
      const Text('حالة التطوير: واجهة القسم جاهزة ضمن الهيكل، والاتصال المباشر بالمصدر الخارجي يحتاج إعداداً واختباراً قبل تفعيله.', style: TextStyle(color: Color(0xFFD6B56D))),
    ])),
  );
}
