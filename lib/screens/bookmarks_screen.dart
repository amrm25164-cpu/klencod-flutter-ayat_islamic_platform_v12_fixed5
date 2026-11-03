import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'mushaf_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _preferences = PreferencesService();
  late Future<List<int>> _pages;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => _pages = _preferences.getBookmarkedPages();

  Future<void> _remove(int page) async {
    await _preferences.toggleBookmarkedPage(page);
    if (!mounted) return;
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('العلامات المرجعية')),
    body: FutureBuilder<List<int>>(
      future: _pages,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final pages = snapshot.data ?? const <int>[];
        if (pages.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bookmark_border, size: 54, color: Color(0xFFD6B56D)),
              SizedBox(height: 12),
              Text('لا توجد صفحات محفوظة بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('افتح المصحف واضغط علامة الحفظ لإضافة صفحة هنا.', textAlign: TextAlign.center),
            ]),
          ));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final page = pages[index];
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.menu_book)),
              title: Text('صفحة المصحف $page'),
              subtitle: const Text('اضغط للانتقال إلى الصفحة'),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MushafScreen(initialPage: page))),
              trailing: IconButton(
                tooltip: 'حذف العلامة',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _remove(page),
              ),
            ));
          },
        );
      },
    ),
  );
}
