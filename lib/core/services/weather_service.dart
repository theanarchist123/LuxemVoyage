import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String city;
  final String country;
  final double tempC;
  final String description;
  final String icon;

  WeatherData({
    required this.city,
    required this.country,
    required this.tempC,
    required this.description,
    required this.icon,
  });
}

class WeatherService {
  // Open-Meteo is free and requires no API key.
  // We get geocoding from Nominatim (also free).

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<WeatherData?> getWeather() async {
    try {
      final pos = await getCurrentPosition();
      if (pos == null) return _defaultWeather();

      final lat = pos.latitude;
      final lon = pos.longitude;

      // Get weather from Open-Meteo (free, no API key)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weathercode'
        '&temperature_unit=celsius'
        '&timezone=auto',
      );

      // Get city name from Nominatim reverse geocoding
      final geoUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json',
      );

      final results = await Future.wait([
        http.get(weatherUrl),
        http.get(geoUrl, headers: {'User-Agent': 'LuxeVoyageApp/1.0'}),
      ]);

      final weatherResp = results[0];
      final geoResp = results[1];

      String city = 'Your Location';
      String country = '';

      if (geoResp.statusCode == 200) {
        final geoJson = jsonDecode(geoResp.body) as Map<String, dynamic>;
        final address = geoJson['address'] as Map<String, dynamic>?;
        city = address?['city'] ??
            address?['town'] ??
            address?['village'] ??
            address?['state'] ??
            'Your Location';
        country = address?['country'] ?? '';
      }

      if (weatherResp.statusCode == 200) {
        final wJson = jsonDecode(weatherResp.body) as Map<String, dynamic>;
        final current = wJson['current'] as Map<String, dynamic>;
        final temp = (current['temperature_2m'] as num).toDouble();
        final code = current['weathercode'] as int;

        return WeatherData(
          city: city,
          country: country,
          tempC: temp,
          description: _weatherDescription(code),
          icon: _weatherIcon(code),
        );
      }

      return _defaultWeather();
    } catch (_) {
      return _defaultWeather();
    }
  }

  WeatherData _defaultWeather() => WeatherData(
        city: 'Your Location',
        country: '',
        tempC: 0,
        description: 'Not Available',
        icon: '🌍',
      );

  String _weatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rainy';
    if (code <= 79) return 'Snowing';
    if (code <= 82) return 'Rain Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String _weatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 59) return '🌦️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 99) return '⛈️';
    return '🌍';
  }
}
