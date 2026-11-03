import 'package:dio/dio.dart';

class QuranSearchResult {
  final int number;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final String text;
  final String edition;

  const QuranSearchResult({
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.text,
    required this.edition,
  });

  factory QuranSearchResult.fromJson(Map<String, dynamic> json) {
    final surah = json['surah'] is Map
        ? Map<String, dynamic>.from(json['surah'] as Map)
        : <String, dynamic>{};
    final edition = json['edition'] is Map
        ? Map<String, dynamic>.from(json['edition'] as Map)
        : <String, dynamic>{};
    return QuranSearchResult(
      number: (json['number'] as num?)?.toInt() ?? 0,
      numberInSurah: (json['numberInSurah'] as num?)?.toInt() ?? 0,
      surahNumber: (surah['number'] as num?)?.toInt() ?? 1,
      surahName: surah['name'] as String? ?? 'سورة',
      text: json['text'] as String? ?? '',
      edition: edition['identifier'] as String? ?? 'ar',
    );
  }

  String get reference => '$surahName • الآية $numberInSurah';
}

class QuranSearchService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 18),
    headers: const {'Accept': 'application/json'},
  ));

  Future<List<QuranSearchResult>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];
    final response = await _dio.get(
      'https://api.alquran.cloud/v1/search/${Uri.encodeComponent(cleanQuery)}/all/ar',
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    if (body['code'] != 200) {
      throw Exception(body['status'] ?? 'تعذر تنفيذ البحث');
    }
    final data = Map<String, dynamic>.from(body['data'] as Map);
    final matches = data['matches'] as List? ?? const [];
    return matches
        .map((item) => QuranSearchResult.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

/// Retrieves a named Quran edition for one ayah. The Arabic Al-Muyassar
/// edition is used as a concise explanatory rendering, not as Quran text.
extension QuranSearchDetails on QuranSearchService {
  Future<String> fetchAyahEdition(int globalAyahNumber, String edition) async {
    if (globalAyahNumber < 1) {
      throw ArgumentError.value(globalAyahNumber, 'globalAyahNumber');
    }
    final response = await _dioForDetails.get(
      'https://api.alquran.cloud/v1/ayah/$globalAyahNumber/$edition',
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    if (body['code'] != 200 || body['data'] is! Map) {
      throw Exception('تعذر تحميل النص المطلوب');
    }
    final data = Map<String, dynamic>.from(body['data'] as Map);
    return (data['text'] as String? ?? '').trim();
  }
}

// Kept separate from the search client so detail requests have their own
// bounded timeouts and do not mutate the search configuration.
final Dio _dioForDetails = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 12),
  receiveTimeout: const Duration(seconds: 18),
  headers: const {'Accept': 'application/json'},
));
