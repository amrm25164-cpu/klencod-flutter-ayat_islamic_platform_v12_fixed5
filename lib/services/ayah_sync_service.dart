import 'package:dio/dio.dart';

class QuranRecitation {
  final int id;
  final String name;
  final String style;
  const QuranRecitation({required this.id, required this.name, required this.style});

  factory QuranRecitation.fromJson(Map<String, dynamic> json) {
    final reciter = json['reciter_name'] ?? json['name'] ?? 'قارئ';
    final style = json['style'] ?? '';
    return QuranRecitation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: reciter.toString(),
      style: style.toString(),
    );
  }
}

class AyahTiming {
  final int ayah;
  final int startMs;
  final int endMs;
  const AyahTiming({required this.ayah, required this.startMs, required this.endMs});
}

class SyncedChapterAudio {
  final String audioUrl;
  final List<AyahTiming> timings;
  const SyncedChapterAudio({required this.audioUrl, required this.timings});
}

/// Uses Quran.com chapter-recitation timing segments. If the provider does not
/// return segment metadata, this service fails explicitly rather than guessing.
class AyahSyncService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.quran.com/api/v4',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 40),
    headers: const {'Accept': 'application/json'},
  ));

  Future<List<QuranRecitation>> getRecitations() async {
    final response = await _dio.get('/resources/recitations', queryParameters: {'language': 'ar'});
    final data = response.data as Map<String, dynamic>;
    final raw = (data['recitations'] ?? data['recitation'] ?? []) as List;
    return raw.map((e) => QuranRecitation.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((e) => e.id > 0).toList();
  }

  Future<SyncedChapterAudio> getChapter(int recitationId, int surah) async {
    final response = await _dio.get('/chapter_recitations/$recitationId/$surah', queryParameters: {'segments': 'true'});
    final data = Map<String, dynamic>.from(response.data as Map);
    final audio = Map<String, dynamic>.from((data['audio_file'] ?? data['audioFile']) as Map);
    final rawUrl = (audio['audio_url'] ?? audio['url'])?.toString() ?? '';
    final rawSegments = audio['segments'] ?? data['segments'];
    if (rawUrl.isEmpty || rawSegments is! List || rawSegments.isEmpty) {
      throw StateError('مصدر التلاوة لم يوفر توقيتات الآيات لهذه السورة.');
    }
    final timings = <AyahTiming>[];
    for (final item in rawSegments) {
      if (item is! List || item.length < 3) continue;
      final key = item[0];
      int? ayah;
      if (key is num) {
        ayah = key.toInt();
      } else {
        final match = RegExp(r'\d+:([0-9]+)').firstMatch(key.toString());
        ayah = match == null ? int.tryParse(key.toString()) : int.tryParse(match.group(1)!);
      }
      final start = (item[1] as num?)?.toInt();
      final end = (item[2] as num?)?.toInt();
      if (ayah != null && start != null && end != null && end > start) {
        timings.add(AyahTiming(ayah: ayah, startMs: start, endMs: end));
      }
    }
    timings.sort((a, b) => a.startMs.compareTo(b.startMs));
    if (timings.isEmpty) throw StateError('لم تصل توقيتات صالحة للآيات من مزود التلاوة.');
    return SyncedChapterAudio(audioUrl: rawUrl, timings: timings);
  }
}
