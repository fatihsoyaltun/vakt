class DailyVerse {
  final int day;
  final String surah;
  final String surahTr;
  final int ayah;
  final String arabic;
  final String turkish;
  final String source;

  const DailyVerse({
    required this.day,
    required this.surah,
    required this.surahTr,
    required this.ayah,
    required this.arabic,
    required this.turkish,
    required this.source,
  });

  factory DailyVerse.fromJson(Map<String, dynamic> json) {
    return DailyVerse(
      day: json['day'] as int,
      surah: json['surah'] as String,
      surahTr: json['surah_tr'] as String,
      ayah: json['ayah'] as int,
      arabic: json['arabic'] as String,
      turkish: json['turkish'] as String,
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'surah': surah,
      'surah_tr': surahTr,
      'ayah': ayah,
      'arabic': arabic,
      'turkish': turkish,
      'source': source,
    };
  }
}
