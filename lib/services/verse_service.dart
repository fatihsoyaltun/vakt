import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/models/verse_model.dart';

class VerseService {
  List<DailyVerse>? _cache;

  Future<List<DailyVerse>> loadVerses() async {
    if (_cache != null) return _cache!;
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/quran_verses.json',
      );
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
      _cache = jsonList
          .map((e) => DailyVerse.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cache!;
    } catch (e) {
      // Fallback verse in case of missing or malformed JSON
      return [
        const DailyVerse(
          day: 1,
          surah: 'Fatiha',
          surahTr: 'Fâtiha',
          ayah: 1,
          arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
          turkish: 'Rahmân ve Rahîm olan Allah\'ın adıyla.',
          source: 'Diyanet İşleri Başkanlığı Meali',
        ),
      ];
    }
  }

  DailyVerse getVerseForDay(int dayOfRamadan, List<DailyVerse> verses) {
    final index = ((dayOfRamadan - 1) % verses.length).clamp(
      0,
      verses.length - 1,
    );
    return verses[index];
  }

  DailyVerse getTodayVerse(List<DailyVerse> verses) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays + 1;
    final index = (dayOfYear % verses.length).clamp(0, verses.length - 1);
    return verses[index];
  }
}
