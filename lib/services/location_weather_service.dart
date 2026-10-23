import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserLocation {
  final String city;
  final String country;
  final double lat;
  final double lon;

  UserLocation({
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
  });

  static UserLocation defaultFallback() {
    return UserLocation(
      city: 'Kampala',
      country: 'Uganda',
      lat: 0.3476,
      lon: 32.5825,
    );
  }
}

class WeatherData {
  final int temperature;
  final String condition;
  final int weatherCode;
  final String city;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.weatherCode,
    required this.city,
  });

  static WeatherData defaultFallback() {
    return WeatherData(
      temperature: 27,
      condition: 'Partly cloudy',
      weatherCode: 2,
      city: 'Kampala',
    );
  }
}

class LocationWeatherService {
  static const String _ipApiUrl = 'http://ip-api.com/json';
  static const String _openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Auto-detects user city & coordinates without requiring GPS permissions
  Future<UserLocation> detectLocation() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await http
          .get(Uri.parse(_ipApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final loc = UserLocation(
            city: data['city'] ?? 'Kampala',
            country: data['country'] ?? 'Uganda',
            lat: (data['lat'] as num?)?.toDouble() ?? 0.3476,
            lon: (data['lon'] as num?)?.toDouble() ?? 32.5825,
          );

          await prefs.setString('cached_user_city', loc.city);
          await prefs.setString('cached_user_country', loc.country);
          await prefs.setDouble('cached_user_lat', loc.lat);
          await prefs.setDouble('cached_user_lon', loc.lon);
          return loc;
        }
      }
    } catch (_) {
      // Offline fallback: try reading cached location
    }

    final cachedCity = prefs.getString('cached_user_city');
    final cachedCountry = prefs.getString('cached_user_country');
    final cachedLat = prefs.getDouble('cached_user_lat');
    final cachedLon = prefs.getDouble('cached_user_lon');

    if (cachedCity != null && cachedLat != null && cachedLon != null) {
      return UserLocation(
        city: cachedCity,
        country: cachedCountry ?? 'Uganda',
        lat: cachedLat,
        lon: cachedLon,
      );
    }

    return UserLocation.defaultFallback();
  }

  /// Fetches real-time temperature & condition from Open-Meteo
  Future<WeatherData> fetchWeather({
    required double lat,
    required double lon,
    required String city,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_weather_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

    try {
      final uri = Uri.parse(
          '$_openMeteoUrl?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;

        if (current != null) {
          final tempRaw = current['temperature_2m'];
          final codeRaw = current['weather_code'];
          final temp = (tempRaw is num) ? tempRaw.round() : 27;
          final code = (codeRaw is int) ? codeRaw : 2;
          final condition = _mapWeatherCode(code);

          final weather = WeatherData(
            temperature: temp,
            condition: condition,
            weatherCode: code,
            city: city,
          );

          await prefs.setString(
              cacheKey,
              jsonEncode({
                'temperature': temp,
                'condition': condition,
                'weatherCode': code,
                'city': city,
              }));

          return weather;
        }
      }
    } catch (_) {
      // Fallback to cache if available
    }

    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return WeatherData(
          temperature: map['temperature'] ?? 27,
          condition: map['condition'] ?? 'Partly cloudy',
          weatherCode: map['weatherCode'] ?? 2,
          city: map['city'] ?? city,
        );
      } catch (_) {}
    }

    return WeatherData.defaultFallback();
  }

  String _mapWeatherCode(int code) {
    if (code == 0) return 'Sunny';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 67) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snowy';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Partly cloudy';
  }
}
