import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static const double _defaultLatitude = 41.0082;
  static const double _defaultLongitude = 28.9784;
  static const String _defaultCity = 'Istanbul';

  Future<bool> checkAndRequestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      // ignore: avoid_print
      print('Location services enabled: $serviceEnabled');
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      // ignore: avoid_print
      print('Location permission (initial): $permission');

      if (permission == LocationPermission.deniedForever) {
        // ignore: avoid_print
        print('Location permission denied forever — cannot request');
        return false;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // ignore: avoid_print
        print('Location permission (after request): $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        // ignore: avoid_print
        print('Location permission denied forever after request');
        return false;
      }

      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      // ignore: avoid_print
      print('Location permission granted: $granted');
      return granted;
    } catch (e) {
      // ignore: avoid_print
      print('Permission check error: $e');
      return false;
    }
  }

  Future<Position> getCurrentPosition() async {
    try {
      final granted = await checkAndRequestPermission();
      if (!granted) {
        // ignore: avoid_print
        print('GPS permission not granted — returning Istanbul defaults');
        return Position(
          latitude: _defaultLatitude,
          longitude: _defaultLongitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // ignore: avoid_print
      print('Attempting GPS getCurrentPosition...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      // ignore: avoid_print
      print('GPS returned: lat=${position.latitude}, lng=${position.longitude}');
      return position;
    } catch (e) {
      // ignore: avoid_print
      print('GPS FAILED: $e');
      return Position(
        latitude: _defaultLatitude,
        longitude: _defaultLongitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  Future<String> getCityName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final cityName = placemarks.first.administrativeArea ??
            placemarks.first.locality ??
            _defaultCity;
        // ignore: avoid_print
        print('City resolved: $cityName');
        return cityName;
      }
      // ignore: avoid_print
      print('City resolved: $_defaultCity (no placemarks)');
      return _defaultCity;
    } catch (e) {
      // ignore: avoid_print
      print('Geocoding error: $e — returning $_defaultCity');
      return _defaultCity;
    }
  }
}
