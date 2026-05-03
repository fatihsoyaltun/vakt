import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/verse_model.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/prayer_time_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/verse_service.dart';

// --- State Classes ---

class LocationState {
  final double lat;
  final double lng;
  final String cityName;
  final bool isLoading;

  const LocationState({
    required this.lat,
    required this.lng,
    required this.cityName,
    required this.isLoading,
  });

  LocationState copyWith({
    double? lat,
    double? lng,
    String? cityName,
    bool? isLoading,
  }) {
    return LocationState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      cityName: cityName ?? this.cityName,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PrayerTimesState {
  final Map<String, DateTime> times;
  final String nextPrayer;
  final bool isLoading;

  const PrayerTimesState({
    required this.times,
    required this.nextPrayer,
    required this.isLoading,
  });

  PrayerTimesState copyWith({
    Map<String, DateTime>? times,
    String? nextPrayer,
    bool? isLoading,
  }) {
    return PrayerTimesState(
      times: times ?? this.times,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- Notifiers ---

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;
  final StorageService _storageService;

  LocationNotifier(this._locationService, this._storageService)
    : super(
        const LocationState(
          lat: 41.0082,
          lng: 28.9784,
          cityName: 'Istanbul',
          isLoading: true,
        ),
      ) {
    _init();
  }

  Future<void> _init() async {
    // ignore: avoid_print
    print('_init: loading cache');
    try {
      final cached = _storageService.getLastLocation();
      if (cached != null) {
        state = LocationState(
          lat: (cached['lat'] as num).toDouble(),
          lng: (cached['lng'] as num).toDouble(),
          cityName: cached['cityName'] as String,
          isLoading: true,
        );
        // ignore: avoid_print
        print(
          '_init: cache loaded (${state.cityName} ${state.lat}, ${state.lng})',
        );
      } else {
        // ignore: avoid_print
        print('_init: no cache found, using defaults');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Location cache read error: $e');
    }
    // ignore: avoid_print
    print('_init: calling fetchLocation for fresh GPS');
    await fetchLocation();
  }

  Future<void> fetchLocation() async {
    // ignore: avoid_print
    print('fetchLocation called');
    try {
      state = state.copyWith(isLoading: true);
      final position = await _locationService.getCurrentPosition();
      final cityName = await _locationService.getCityName(
        position.latitude,
        position.longitude,
      );
      // ignore: avoid_print
      print(
        'Location result: lat=${position.latitude}, lng=${position.longitude}, city=$cityName',
      );
      state = LocationState(
        lat: position.latitude,
        lng: position.longitude,
        cityName: cityName,
        isLoading: false,
      );
      // ignore: avoid_print
      print('Saving to cache and updating state');
      await _storageService.saveLastLocation(
        position.latitude,
        position.longitude,
        cityName,
      );
      // Re-schedule notifications with fresh coordinates
      NotificationService.scheduleDailyNotifications(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Location fetch error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

class PrayerTimesNotifier extends StateNotifier<PrayerTimesState> {
  final PrayerTimeService _prayerTimeService;

  PrayerTimesNotifier(this._prayerTimeService)
    : super(const PrayerTimesState(times: {}, nextPrayer: '', isLoading: true));

  void loadPrayerTimes(double lat, double lng) {
    state = state.copyWith(isLoading: true);
    final times = _prayerTimeService.getDailyPrayerTimes(
      lat,
      lng,
      DateTime.now(),
    );
    final nextPrayer = _prayerTimeService.getNextPrayer(lat, lng);
    state = PrayerTimesState(
      times: times,
      nextPrayer: nextPrayer,
      isLoading: false,
    );
  }
}

// --- Providers ---

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier(LocationService(), StorageService());
  },
);

final prayerTimesProvider =
    StateNotifierProvider<PrayerTimesNotifier, PrayerTimesState>((ref) {
      final notifier = PrayerTimesNotifier(PrayerTimeService());
      final location = ref.watch(locationProvider);
      if (!location.isLoading) {
        notifier.loadPrayerTimes(location.lat, location.lng);
      }
      return notifier;
    });

final iftarCountdownProvider = StreamProvider<Duration>((ref) {
  final location = ref.watch(locationProvider);
  final prayerTimeService = PrayerTimeService();

  Stream<Duration> stream() async* {
    if (location.isLoading) {
      yield Duration.zero;
      return;
    }
    yield prayerTimeService.getTimeUntilIftar(location.lat, location.lng);
    yield* Stream.periodic(const Duration(seconds: 1), (_) {
      return prayerTimeService.getTimeUntilIftar(location.lat, location.lng);
    });
  }

  return stream();
});

final sahurCountdownProvider = StreamProvider<Duration>((ref) {
  final location = ref.watch(locationProvider);
  final prayerTimeService = PrayerTimeService();

  Stream<Duration> stream() async* {
    if (location.isLoading) {
      yield Duration.zero;
      return;
    }
    yield prayerTimeService.getTimeUntilSahur(location.lat, location.lng);
    yield* Stream.periodic(const Duration(seconds: 1), (_) {
      return prayerTimeService.getTimeUntilSahur(location.lat, location.lng);
    });
  }

  return stream();
});

// --- Theme / Accessibility ---

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeModeNotifier(this._storageService)
    : super(
        (_storageService.getSetting<bool>('dark_mode') ?? true)
            ? ThemeMode.dark
            : ThemeMode.light,
      );

  void toggle() {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    _storageService.saveSetting('dark_mode', !isDark);
  }
}

class LargeFontNotifier extends StateNotifier<bool> {
  final StorageService _storageService;

  LargeFontNotifier(this._storageService)
    : super(_storageService.getSetting<bool>('large_font') ?? false);

  void toggle() {
    final newValue = !state;
    state = newValue;
    _storageService.saveSetting('large_font', newValue);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(StorageService());
});

final largeFontProvider = StateNotifierProvider<LargeFontNotifier, bool>((
  ref,
) {
  return LargeFontNotifier(StorageService());
});

// --- Verse ---

final verseProvider = FutureProvider<DailyVerse>((ref) async {
  final service = VerseService();
  final verses = await service.loadVerses();
  return service.getTodayVerse(verses);
});
