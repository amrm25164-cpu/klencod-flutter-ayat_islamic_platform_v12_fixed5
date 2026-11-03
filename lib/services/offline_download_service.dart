import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';
import 'quran_service.dart';

class OfflineDownloadItem {
  final int surah;
  final String surahName;
  final String reciterName;
  final String textPath;
  final String audioPath;
  final int bytes;
  const OfflineDownloadItem({required this.surah, required this.surahName, required this.reciterName, required this.textPath, required this.audioPath, required this.bytes});
  Map<String, dynamic> toJson() => {'surah': surah, 'surahName': surahName, 'reciterName': reciterName, 'textPath': textPath, 'audioPath': audioPath, 'bytes': bytes};
  factory OfflineDownloadItem.fromJson(Map<String, dynamic> j) => OfflineDownloadItem(surah: j['surah'] as int, surahName: j['surahName'] as String, reciterName: j['reciterName'] as String, textPath: j['textPath'] as String, audioPath: j['audioPath'] as String, bytes: j['bytes'] as int? ?? 0);
}

class OfflineDownloadService {
  static const _key = 'ayat_offline_downloads_v1';
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 5)));

  Future<Directory> _folder() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/ayat_offline');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<OfflineDownloadItem>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final items = <OfflineDownloadItem>[];
    for (final value in raw) {
      try {
        final item = OfflineDownloadItem.fromJson(jsonDecode(value) as Map<String, dynamic>);
        if (await File(item.textPath).exists() && await File(item.audioPath).exists()) items.add(item);
      } catch (_) {}
    }
    return items;
  }

  Future<OfflineDownloadItem> downloadSurah(SurahInfo surah, Reciter reciter, {ProgressCallback? onProgress}) async {
    if (reciter.server.isEmpty) throw StateError('رابط القارئ غير متاح');
    final available = reciter.surahList.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toSet();
    if (available.isNotEmpty && !available.contains(surah.number)) throw StateError('هذه السورة غير متاحة لهذا القارئ');
    final dir = await _folder();
    final textFile = File('${dir.path}/surah_${surah.number}.json');
    final audioFile = File('${dir.path}/surah_${surah.number}_${reciter.id}.mp3');
    try {
      final response = await _dio.get('https://api.alquran.cloud/v1/surah/${surah.number}/quran-uthmani');
      await textFile.writeAsString(jsonEncode(response.data), flush: true);
      await _dio.download(reciter.audioUrl(surah.number), audioFile.path, onReceiveProgress: onProgress, deleteOnError: true);
      final bytes = await textFile.length() + await audioFile.length();
      final item = OfflineDownloadItem(surah: surah.number, surahName: surah.name, reciterName: reciter.name, textPath: textFile.path, audioPath: audioFile.path, bytes: bytes);
      final prefs = await SharedPreferences.getInstance();
      final all = (prefs.getStringList(_key) ?? []).where((raw) {
        try { return (jsonDecode(raw) as Map<String, dynamic>)['surah'] != surah.number; } catch (_) { return false; }
      }).toList();
      all.add(jsonEncode(item.toJson()));
      await prefs.setStringList(_key, all);
      return item;
    } catch (_) {
      if (await audioFile.exists()) await audioFile.delete();
      rethrow;
    }
  }

  Future<void> delete(OfflineDownloadItem item) async {
    for (final path in [item.textPath, item.audioPath]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    final all = (prefs.getStringList(_key) ?? []).where((raw) {
      try { return (jsonDecode(raw) as Map<String, dynamic>)['surah'] != item.surah; } catch (_) { return false; }
    }).toList();
    await prefs.setStringList(_key, all);
  }
}
