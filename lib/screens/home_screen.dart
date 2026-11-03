import 'package:flutter/material.dart';
import 'mushaf_screen.dart';
import 'reading_screen.dart';
import 'reciters_screen.dart';
import 'adhkar_screen.dart';
import 'advanced_hub_screen.dart';
import 'prayer_screen.dart';
import 'quran_search_screen.dart';
import 'reading_goal_screen.dart';
import 'assistant_screen.dart';
import 'bookmarks_screen.dart';
import 'surah_index_screen.dart';
import 'tafsir_screen.dart';
import '../services/preferences_service.dart';
import 'offline_downloads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _screens = const [
    _HomeDashboard(),
    MushafScreen(),
    AdvancedHubScreen(),
    PrayerScreen(),
    _LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'المصحف'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'المركز'),
          NavigationDestination(icon: Icon(Icons.mosque_outlined), label: 'الصلاة'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'المكتبة'),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Text('السَّلَامُ عَلَيْك', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('آيات', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: color.secondary, fontWeight: FontWeight.bold)),
          const Text('رفيقك اليومي مع القرآن الكريم'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B654D), Color(0xFF102820)],
                begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.secondary.withOpacity(.35)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',
                style: TextStyle(fontSize: 25, height: 1.8, color: Colors.white)),
              const SizedBox(height: 8),
              Text('سورة المزمل • الآية ٤',
                style: TextStyle(color: Colors.white.withOpacity(.8))),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MushafScreen())),
                icon: const Icon(Icons.menu_book),
                label: const Text('ابدأ القراءة'),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          FutureBuilder<int>(
            future: PreferencesService().getLastPage(),
            builder: (context, snapshot) {
              final page = snapshot.data ?? 1;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.history, color: Color(0xFFD6B56D))),
                  title: const Text('متابعة آخر قراءة'),
                  subtitle: Text('آخر صفحة وصلت إليها: $page'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MushafScreen(initialPage: page))),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          Text('اكتشف آيات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _FeatureTile(icon: Icons.list_alt, title: 'فهرس سور القرآن',
            subtitle: 'السور الـ114 مع البحث والفتح المباشر',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurahIndexScreen()))),
          _FeatureTile(icon: Icons.auto_stories, title: 'مصحف المدينة',
            subtitle: 'تصفح صفحات المصحف من 1 إلى 604',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MushafScreen()))),
          _FeatureTile(icon: Icons.play_circle_outline, title: 'القراءة المتتابعة',
            subtitle: 'اقرأ السورة آية بعد آية',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingScreen()))),
          _FeatureTile(icon: Icons.download_for_offline, title: 'التنزيلات دون إنترنت',
            subtitle: 'نزّل السور والتلاوات لإدارتها على جهازك',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineDownloadsScreen()))),
          _FeatureTile(icon: Icons.headphones, title: 'مكتبة القراء',
            subtitle: 'استكشف القراء والروايات المتاحة',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecitersScreen()))),
          _FeatureTile(icon: Icons.volunteer_activism, title: 'الأذكار',
            subtitle: 'أذكار يومية وسبحة إلكترونية',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhkarScreen()))),
          Card(child: ListTile(leading: const Icon(Icons.bookmark_outline, color: Color(0xFFD6B56D)), title: const Text('العلامات المرجعية'), subtitle: const Text('ارجع بسرعة إلى صفحاتك المحفوظة'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen())))),
          Card(child: ListTile(leading: const Icon(Icons.track_changes, color: Color(0xFFD6B56D)), title: const Text('وردي اليومي'), subtitle: const Text('حدد عدد الصفحات وسجّل تقدمك'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingGoalScreen())))),
          Card(child: ListTile(leading: const Icon(Icons.search, color: Color(0xFFD6B56D)), title: const Text('البحث في القرآن الكريم'), subtitle: const Text('ابحث عن الآيات بالكلمات والعبارات واحفظ النتائج'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranSearchScreen())))),
          _FeatureTile(icon: Icons.menu_book, title: 'الحديث والتخريج', subtitle: 'بحث في مصادر السنة وشروح الحديث'),
          _FeatureTile(icon: Icons.auto_stories, title: 'التفسير والترجمات', subtitle: 'اعرض الآية مع التفسير والترجمة المتاحة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TafsirScreen()))),
          Card(child: ListTile(leading: const Icon(Icons.psychology_alt, color: Color(0xFFD6B56D)), title: const Text('رفيق آيات الذكي'), subtitle: const Text('مساعد معلوماتي مع تنبيه لمراجعة المصادر'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantScreen())))),
          const SizedBox(height: 16),
          const Text('تنبيه: يلزم الاتصال بالإنترنت لجلب النصوص والتلاوات في هذه النسخة الأولية.'),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _FeatureTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.2),
        child: Icon(icon, color: Theme.of(context).colorScheme.secondary)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    ),
  );
}


class _LibraryScreen extends StatelessWidget {
  const _LibraryScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مكتبة آيات')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('محتواك الإسلامي في مكان واحد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Card(child: ListTile(leading: const Icon(Icons.list_alt, color: Color(0xFFD6B56D)), title: const Text('فهرس سور القرآن'), subtitle: const Text('بحث وفتح أي سورة مباشرة'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurahIndexScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.download_for_offline, color: Color(0xFFD6B56D)), title: const Text('التنزيلات دون إنترنت'), subtitle: const Text('إدارة السور والتلاوات المحفوظة على الجهاز'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineDownloadsScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.headphones, color: Color(0xFFD6B56D)), title: const Text('مكتبة القراء'), subtitle: const Text('استمع إلى التلاوات المتاحة'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecitersScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.favorite, color: Color(0xFFD6B56D)), title: const Text('الأذكار والسبحة'), subtitle: const Text('أذكار يومية وعداد تسبيح'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhkarScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.bookmark_outline, color: Color(0xFFD6B56D)), title: const Text('العلامات المرجعية'), subtitle: const Text('صفحات المصحف التي حفظتها'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.chrome_reader_mode, color: Color(0xFFD6B56D)), title: const Text('القراءة المتتابعة'), subtitle: const Text('قراءة السور آية بعد آية'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.auto_stories, color: Color(0xFFD6B56D)), title: const Text('التفسير والترجمات'), subtitle: const Text('فهم الآيات من المصادر المتاحة'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TafsirScreen())))),
    ]),
  );
}
