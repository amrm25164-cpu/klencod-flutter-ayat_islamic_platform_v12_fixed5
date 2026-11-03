class Ayah {
  final int number;
  final int numberInSurah;
  final int surahNumber;
  final int page;
  final String text;
  final String surahName;

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.page,
    required this.text,
    required this.surahName,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    final surah = (json['surah'] as Map<String, dynamic>?) ?? {};
    return Ayah(
      number: json['number'] as int? ?? 0,
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      surahNumber: surah['number'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      text: json['text'] as String? ?? '',
      surahName: surah['name'] as String? ?? '',
    );
  }
}

class Reciter {
  final int id;
  final String name;
  final String server;
  final String surahList;
  final String moshafName;

  const Reciter({
    required this.id,
    required this.name,
    required this.server,
    required this.surahList,
    required this.moshafName,
  });

  factory Reciter.fromJson(Map<String, dynamic> json, Map<String, dynamic> moshaf) {
    return Reciter(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'قارئ',
      server: moshaf['server'] as String? ?? '',
      surahList: moshaf['surah_list'] as String? ?? '',
      moshafName: moshaf['name'] as String? ?? '',
    );
  }

  String audioUrl(int surah) =>
      '$server${surah.toString().padLeft(3, '0')}.mp3';
}


class SurahInfo {
  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final int numberOfAyahs;

  const SurahInfo({required this.number, required this.name, required this.englishName, required this.revelationType, required this.numberOfAyahs});

  factory SurahInfo.fromJson(Map<String, dynamic> json) => SurahInfo(
    number: json['number'] as int? ?? 1,
    name: json['name'] as String? ?? '',
    englishName: json['englishName'] as String? ?? '',
    revelationType: json['revelationType'] as String? ?? '',
    numberOfAyahs: json['numberOfAyahs'] as int? ?? 0,
  );
}
