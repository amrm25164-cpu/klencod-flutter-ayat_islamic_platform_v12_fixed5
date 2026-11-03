import 'package:dio/dio.dart';
import '../models/quran_models.dart';

class QuranService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Future<List<Ayah>> getPage(int page) async {
    final response = await _dio.get(
      'https://api.alquran.cloud/v1/page/$page/quran-uthmani',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final list = data['ayahs'];
    return (list as List)
        .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Ayah>> getSurah(int surah) async {
    final response = await _dio.get(
      'https://api.alquran.cloud/v1/surah/$surah/quran-uthmani',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final surahName = data['name'] as String? ?? '';
    return (data['ayahs'] as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['surah'] = {'number': surah, 'name': surahName};
      return Ayah.fromJson(map);
    }).toList();
  }

  Future<List<SurahInfo>> getSurahs() async {
    final response = await _dio.get('https://api.alquran.cloud/v1/meta');
    final data = response.data['data'] as Map<String, dynamic>;
    final surahs = data['surahs'] as Map<String, dynamic>;
    final references = surahs['references'] as List;
    return references
        .map((item) => SurahInfo.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<int> getSurahFirstPage(int surah) async {
    final ayahs = await getSurah(surah);
    if (ayahs.isEmpty) throw StateError('لا توجد آيات لهذه السورة');
    return ayahs.first.page;
  }

  Future<List<Reciter>> getReciters() async {
    final response = await _dio.get(
      'https://mp3quran.net/api/v3/reciters',
      queryParameters: {'language': 'ar'},
    );
    final list = response.data['reciters'] as List? ?? [];
    final result = <Reciter>[];
    for (final item in list) {
      final reciter = Map<String, dynamic>.from(item as Map);
      final reads = reciter['moshaf'] as List? ?? [];
      if (reads.isNotEmpty) {
        result.add(Reciter.fromJson(
          reciter,
          Map<String, dynamic>.from(reads.first as Map),
        ));
      }
    }
    return result;
  }
}
