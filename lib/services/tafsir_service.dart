import 'package:dio/dio.dart';

class QuranEdition {
  final String identifier;
  final String name;
  final String englishName;
  final String language;
  final String type;

  const QuranEdition({
    required this.identifier,
    required this.name,
    required this.englishName,
    required this.language,
    required this.type,
  });

  factory QuranEdition.fromJson(Map<String, dynamic> json) => QuranEdition(
        identifier: json['identifier'] as String? ?? '',
        name: json['name'] as String? ?? '',
        englishName: json['englishName'] as String? ?? '',
        language: json['language'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );

  String get displayName => name.isNotEmpty ? name : englishName;
}

class AyahStudyResult {
  final String text;
  final int number;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final int page;

  const AyahStudyResult({
    required this.text,
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.page,
  });

  factory AyahStudyResult.fromJson(Map<String, dynamic> json) {
    final surah = Map<String, dynamic>.from(json['surah'] as Map? ?? {});
    return AyahStudyResult(
      text: json['text'] as String? ?? '',
      number: json['number'] as int? ?? 0,
      numberInSurah: json['numberInSurah'] as int? ?? 1,
      surahNumber: surah['number'] as int? ?? 1,
      surahName: surah['name'] as String? ?? '',
      page: json['page'] as int? ?? 1,
    );
  }
}

class TafsirService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.alquran.cloud/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Future<List<QuranEdition>> getEditions(String type, {String? language}) async {
    final response = await _dio.get('/edition', queryParameters: {
      'format': 'text',
      'type': type,
      if (language != null) 'language': language,
    });
    final data = response.data['data'] as List? ?? [];
    return data
        .map((item) => QuranEdition.fromJson(Map<String, dynamic>.from(item as Map)))
        .where((edition) => edition.identifier.isNotEmpty)
        .toList();
  }

  Future<AyahStudyResult> getAyah(int surah, int ayah, String edition) async {
    final response = await _dio.get('/ayah/$surah:$ayah/$edition');
    return AyahStudyResult.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }
}
