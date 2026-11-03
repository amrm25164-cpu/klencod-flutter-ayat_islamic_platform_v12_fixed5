import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';
import '../services/preferences_service.dart';

class MushafScreen extends StatefulWidget {
  final int? initialPage;
  const MushafScreen({super.key, this.initialPage});
  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final _service = QuranService();
  final _prefs = PreferencesService();
  late final PageController _controller;
  int _page = 1;
  Future<List<Ayah>>? _future;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _page = (widget.initialPage ?? 1).clamp(1, 604);
    _controller = PageController(initialPage: _page - 1);
    _future = _service.getPage(_page);
    if (widget.initialPage == null) {
      _loadSavedPage();
    } else {
      _prefs.saveLastPage(_page);
    }
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final pages = await _prefs.getBookmarkedPages();
    if (mounted) setState(() => _isBookmarked = pages.contains(_page));
  }

  Future<void> _toggleBookmark() async {
    final added = await _prefs.toggleBookmarkedPage(_page);
    if (!mounted) return;
    setState(() => _isBookmarked = added);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added ? 'تم حفظ الصفحة في العلامات المرجعية' : 'تم حذف العلامة المرجعية'),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _loadSavedPage() async {
    final saved = (await _prefs.getLastPage()).clamp(1, 604);
    if (!mounted) return;
    _controller.jumpToPage(saved - 1);
    setState(() {
      _page = saved;
      _future = _service.getPage(saved);
    });
    _loadBookmarkState();
  }

  void _changePage(int index) {
    final page = index + 1;
    setState(() {
      _page = page;
      _future = _service.getPage(page);
    });
    _prefs.saveLastPage(page);
    _loadBookmarkState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مصحف المدينة'),
        actions: [
          IconButton(
            tooltip: _isBookmarked ? 'إزالة العلامة المرجعية' : 'حفظ الصفحة',
            onPressed: _toggleBookmark,
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined),
          ),
          IconButton(
            tooltip: 'الصفحة السابقة',
            onPressed: _page > 1 ? () => _controller.previousPage(
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut) : null,
            icon: const Icon(Icons.chevron_right),
          ),
          Center(child: Text('$_page / 604')),
          IconButton(
            tooltip: 'الصفحة التالية',
            onPressed: _page < 604 ? () => _controller.nextPage(
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut) : null,
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        reverse: true,
        itemCount: 604,
        onPageChanged: _changePage,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          return FutureBuilder<List<Ayah>>(
            future: pageNumber == _page ? _future : _service.getPage(pageNumber),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('تعذر تحميل الصفحة. تحقق من اتصال الإنترنت.'),
                  TextButton(onPressed: () => setState(() {
                    _page = pageNumber; _future = _service.getPage(pageNumber);
                  }), child: const Text('إعادة المحاولة')),
                ]));
              }
              final ayahs = snapshot.data!;
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F1DF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1B879), width: 2),
                ),
                child: Column(children: [
                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xFF9A8350))),
                    Text(' الجزء ${_juzLabel(ayahs)} ',
                      style: const TextStyle(color: Color(0xFF66542C))),
                    const Expanded(child: Divider(color: Color(0xFF9A8350))),
                  ]),
                  const SizedBox(height: 14),
                  Expanded(child: SingleChildScrollView(
                    child: Text(
                      ayahs.map((a) => '${a.text} ۞').join(' '),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Color(0xFF241D13), fontSize: 25, height: 2.15,
                        fontFamily: 'KFGQPCUthmanic'),
                    ),
                  )),
                  const SizedBox(height: 12),
                  Text('صفحة $pageNumber',
                    style: const TextStyle(color: Color(0xFF66542C))),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  String _juzLabel(List<Ayah> ayahs) => ayahs.isEmpty ? '—' : 'المصحف الشريف';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
