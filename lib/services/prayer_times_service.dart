import 'package:dio/dio.dart';

/// Prayer-time client. Uses AlAdhan's public timings-by-city endpoint.
/// The selected method is explicit so the UI can disclose calculation settings.
class PrayerTimesService {
  PrayerTimesService({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  Future<Map<String, dynamic>> byCity({required String city, required String country, int method = 5}) async {
    final response = await _dio.get('https://api.aladhan.com/v1/timingsByCity', queryParameters: {'city': city, 'country': country, 'method': method});
    if (response.data is! Map || response.data['data'] is! Map || response.data['data']['timings'] is! Map) {
      throw const FormatException('Invalid prayer times response');
    }
    return Map<String, dynamic>.from(response.data['data']['timings'] as Map);
  }
}
