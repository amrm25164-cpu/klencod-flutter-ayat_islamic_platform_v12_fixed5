import 'package:dio/dio.dart';

class AssistantReply {
  final String answer;
  final String label;
  final List<String> sources;
  final bool requiresVerification;
  const AssistantReply({required this.answer, required this.label, required this.sources, required this.requiresVerification});
  factory AssistantReply.fromJson(Map<String, dynamic> json) => AssistantReply(
    answer: (json['answer'] ?? '').toString(),
    label: (json['label'] ?? 'إجابة مولّدة').toString(),
    sources: (json['sources'] is List ? (json['sources'] as List) : const []).map((e) => e.toString()).toList(),
    requiresVerification: json['requires_verification'] == true,
  );
}

class AssistantService {
  static const _baseUrl = String.fromEnvironment('AYAT_API_BASE_URL');
  static const _token = String.fromEnvironment('AYAT_APP_TOKEN');
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 45), headers: {'Accept': 'application/json', if (_token.isNotEmpty) 'X-AYAT-APP-TOKEN': _token}));
  bool get isConfigured => _baseUrl.trim().isNotEmpty && _token.trim().isNotEmpty;

  Future<AssistantReply> ask(String question, {String context = ''}) async {
    if (!isConfigured) throw StateError('لم يتم إعداد عنوان الخادم ورمز التطبيق.');
    final base = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    final response = await _dio.post('$base/assistant/ask', data: {'question': question, 'context': context});
    if (response.data is! Map) throw const FormatException('استجابة المساعد غير صحيحة');
    return AssistantReply.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
