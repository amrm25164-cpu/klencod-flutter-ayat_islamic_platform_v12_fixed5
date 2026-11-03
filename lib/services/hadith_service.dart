import 'package:dio/dio.dart';

/// Connects only to the user's own secure AYAT backend. Never put provider
/// credentials (including OpenAI or private database tokens) in the mobile app.
class HadithRecord {
  final String text;
  final String source;
  final String reference;
  final String grade;
  final String? narrator;
  final String? url;
  const HadithRecord({required this.text, required this.source, required this.reference, required this.grade, this.narrator, this.url});

  factory HadithRecord.fromJson(Map<String, dynamic> json) => HadithRecord(
    text: (json['text'] ?? json['arabic'] ?? json['body'] ?? '').toString(),
    source: (json['source'] ?? json['book'] ?? 'المصدر غير محدد').toString(),
    reference: (json['reference'] ?? json['number'] ?? '').toString(),
    grade: (json['grade'] ?? json['grading'] ?? 'لم تُذكر الدرجة').toString(),
    narrator: json['narrator']?.toString(),
    url: json['url']?.toString(),
  );
}

class HadithService {
  static const _baseUrl = String.fromEnvironment('AYAT_API_BASE_URL');
  static const _token = String.fromEnvironment('AYAT_APP_TOKEN');
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20), headers: {'Accept': 'application/json', if (_token.isNotEmpty) 'X-AYAT-APP-TOKEN': _token}));
  bool get isConfigured => _baseUrl.trim().isNotEmpty && _token.trim().isNotEmpty;

  Future<List<HadithRecord>> search(String query) async {
    if (!isConfigured) throw StateError('لم يتم إعداد خادم آيات للحديث بعد');
    final base = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    final response = await _dio.get('$base/hadith/search', queryParameters: {'q': query.trim()});
    final body = response.data;
    final list = body is List ? body : (body is Map ? (body['results'] ?? body['data'] ?? const []) : const []);
    if (list is! List) throw const FormatException('صيغة استجابة خادم الحديث غير صحيحة');
    return list.whereType<Map>().map((e) => HadithRecord.fromJson(Map<String, dynamic>.from(e))).where((e) => e.text.trim().isNotEmpty).toList();
  }
}
