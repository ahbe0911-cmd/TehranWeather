import 'dart:convert';
import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class LocationProblem implements Exception {
  const LocationProblem(this.message, {this.permanentlyDenied = false});

  final String message;
  final bool permanentlyDenied;

  @override
  String toString() => message;
}

class LocationStore {
  static const _selectedKey = 'selected_location_v3';
  static const _promptedKey = 'location_permission_prompted_v3';

  Future<GeoPointInfo?> loadSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_selectedKey);
      if (raw == null || raw.isEmpty) return null;
      return GeoPointInfo.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelected(GeoPointInfo point) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, jsonEncode(point.toJson()));
  }

  Future<bool> wasPermissionPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptedKey) ?? false;
  }

  Future<void> markPermissionPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
  }
}

class LocationService {
  final Geocoding _geocoding = Geocoding();

  Future<GeoPointInfo> locate({bool requestPermission = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationProblem(
        'موقعیت مکانی دستگاه خاموش است. GPS را روشن کنید یا شهر را دستی جستجو کنید.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationProblem(
        'دسترسی موقعیت داده نشده است. می‌توانید شهر را دستی جستجو کنید.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationProblem(
        'دسترسی موقعیت در تنظیمات Android غیرفعال است. می‌توانید شهر را دستی جستجو کنید.',
        permanentlyDenied: true,
      );
    }

    Position position;
    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 18),
      );
      position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
    } catch (_) {
      final fallback = await Geolocator.getLastKnownPosition();
      if (fallback == null) {
        throw const LocationProblem(
          'GPS مختصات قابل استفاده‌ای برنگرداند. در فضای باز دوباره امتحان کنید یا شهر را جستجو کنید.',
        );
      }
      position = fallback;
    }

    var label = 'موقعیت فعلی';
    String? addressLine;
    try {
      final places = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final primary = <String?>[
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).toList();
        if (primary.isNotEmpty) label = primary.first;

        final full = <String?>[
          p.thoroughfare,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.country,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).toSet().toList();
        if (full.isNotEmpty) addressLine = full.join('، ');
      }
    } catch (_) {
      // Exact coordinates remain valid even when reverse geocoding is unavailable.
    }

    return GeoPointInfo(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      label: label,
      addressLine: addressLine,
    );
  }

  Future<List<GeoPointInfo>> search(String query) async {
    final text = query.trim();
    if (text.length < 2) return const [];

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': text,
      'count': '8',
      'language': 'fa',
      'format': 'json',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('جستجوی شهر در دسترس نیست.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = body['results'] as List<dynamic>? ?? const [];
    return rows.whereType<Map>().map((raw) {
      final item = raw.cast<String, dynamic>();
      final name = item['name'] as String? ?? 'موقعیت';
      final admin = <String?>[
        item['admin1'] as String?,
        item['admin2'] as String?,
        item['country'] as String?,
      ].whereType<String>().where((e) => e.trim().isNotEmpty).toSet().toList();
      return GeoPointInfo(
        latitude: (item['latitude'] as num).toDouble(),
        longitude: (item['longitude'] as num).toDouble(),
        accuracy: 0,
        label: name,
        addressLine: admin.isEmpty ? null : admin.join('، '),
      );
    }).toList();
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();
}

class WeatherService {
  const WeatherService();

  Future<WeatherSnapshot> fetch(GeoPointInfo location) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toStringAsFixed(6),
      'longitude': location.longitude.toStringAsFixed(6),
      'current': [
        'temperature_2m',
        'relative_humidity_2m',
        'apparent_temperature',
        'is_day',
        'precipitation',
        'rain',
        'showers',
        'snowfall',
        'weather_code',
        'cloud_cover',
        'pressure_msl',
        'wind_speed_10m',
        'wind_direction_10m',
      ].join(','),
      'hourly': [
        'temperature_2m',
        'precipitation_probability',
        'precipitation',
        'weather_code',
        'wind_speed_10m',
      ].join(','),
      'daily': [
        'weather_code',
        'temperature_2m_max',
        'temperature_2m_min',
        'precipitation_probability_max',
        'sunrise',
        'sunset',
      ].join(','),
      'timezone': 'auto',
      'forecast_days': '7',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('خطا در دریافت اطلاعات هواشناسی (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final currentJson = (json['current'] as Map).cast<String, dynamic>();
    final hourlyJson = (json['hourly'] as Map).cast<String, dynamic>();
    final dailyJson = (json['daily'] as Map).cast<String, dynamic>();

    final minutely = await _fetchNowcast(location);
    final rawPrecipitation = math.max(
      _double(currentJson['precipitation']),
      math.max(_double(currentJson['rain']), _double(currentJson['showers'])),
    );
    final nearbyPrecipitation = minutely.isEmpty
        ? 0.0
        : minutely.take(2).fold<double>(
              0,
              (value, item) => math.max(value, item.precipitation),
            );
    final effectivePrecipitation = math.max(rawPrecipitation, nearbyPrecipitation);
    final snowfall = _double(currentJson['snowfall']);
    final effectiveCode = _effectiveWeatherCode(
      _int(currentJson['weather_code']),
      effectivePrecipitation,
      snowfall,
    );

    final current = CurrentWeather(
      temperature: _double(currentJson['temperature_2m']),
      apparentTemperature: _double(currentJson['apparent_temperature']),
      humidity: _int(currentJson['relative_humidity_2m']),
      pressure: _double(currentJson['pressure_msl']),
      windSpeed: _double(currentJson['wind_speed_10m']),
      windDirection: _double(currentJson['wind_direction_10m']),
      precipitation: effectivePrecipitation,
      cloudCover: _int(currentJson['cloud_cover']),
      weatherCode: effectiveCode,
      isDay: _int(currentJson['is_day']) == 1,
      time: DateTime.parse(currentJson['time'] as String),
    );

    final times = _list(hourlyJson['time']);
    final temps = _list(hourlyJson['temperature_2m']);
    final pops = _list(hourlyJson['precipitation_probability']);
    final amounts = _list(hourlyJson['precipitation']);
    final codes = _list(hourlyJson['weather_code']);
    final winds = _list(hourlyJson['wind_speed_10m']);

    final now = current.time;
    final hourly = <HourlyWeather>[];
    for (var i = 0; i < times.length; i++) {
      final time = DateTime.parse(times[i] as String);
      if (time.isBefore(now.subtract(const Duration(hours: 1)))) continue;
      final amount = i < amounts.length ? _double(amounts[i]) : 0;
      hourly.add(HourlyWeather(
        time: time,
        temperature: i < temps.length ? _double(temps[i]) : 0,
        precipitationProbability: i < pops.length ? _int(pops[i]) : 0,
        precipitation: amount,
        weatherCode: _effectiveWeatherCode(
          i < codes.length ? _int(codes[i]) : 0,
          amount,
          0,
        ),
        windSpeed: i < winds.length ? _double(winds[i]) : 0,
      ));
      if (hourly.length >= 24) break;
    }

    final dates = _list(dailyJson['time']);
    final maxTemps = _list(dailyJson['temperature_2m_max']);
    final minTemps = _list(dailyJson['temperature_2m_min']);
    final dailyPops = _list(dailyJson['precipitation_probability_max']);
    final dailyCodes = _list(dailyJson['weather_code']);
    final sunrises = _list(dailyJson['sunrise']);
    final sunsets = _list(dailyJson['sunset']);

    final daily = <DailyWeather>[];
    for (var i = 0; i < dates.length; i++) {
      daily.add(DailyWeather(
        date: DateTime.parse(dates[i] as String),
        maxTemperature: i < maxTemps.length ? _double(maxTemps[i]) : 0,
        minTemperature: i < minTemps.length ? _double(minTemps[i]) : 0,
        precipitationProbability: i < dailyPops.length ? _int(dailyPops[i]) : 0,
        weatherCode: i < dailyCodes.length ? _int(dailyCodes[i]) : 0,
        sunrise: DateTime.parse(sunrises[i] as String),
        sunset: DateTime.parse(sunsets[i] as String),
      ));
    }

    return WeatherSnapshot(
      location: location,
      current: current,
      minutely: minutely,
      hourly: hourly,
      daily: daily,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<MinuteWeather>> _fetchNowcast(GeoPointInfo location) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': location.latitude.toStringAsFixed(6),
        'longitude': location.longitude.toStringAsFixed(6),
        'minutely_15': 'precipitation,weather_code',
        'forecast_minutely_15': '8',
        'past_minutely_15': '1',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final block = json['minutely_15'];
      if (block is! Map) return const [];
      final data = block.cast<String, dynamic>();
      final times = _list(data['time']);
      final precipitation = _list(data['precipitation']);
      final codes = _list(data['weather_code']);
      final result = <MinuteWeather>[];
      for (var i = 0; i < times.length; i++) {
        final amount = i < precipitation.length ? _double(precipitation[i]) : 0;
        result.add(MinuteWeather(
          time: DateTime.parse(times[i] as String),
          precipitation: amount,
          weatherCode: _effectiveWeatherCode(
            i < codes.length ? _int(codes[i]) : 0,
            amount,
            0,
          ),
        ));
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  static int _effectiveWeatherCode(int rawCode, double precipitation, double snowfall) {
    if (snowfall > 0.01) {
      return snowfall >= 1 ? 73 : 71;
    }
    if (precipitation > 0.02) {
      if (precipitation < .25) return 51;
      if (precipitation < 1.5) return 61;
      if (precipitation < 4) return 63;
      return 65;
    }
    return rawCode;
  }

  static List<dynamic> _list(dynamic value) => value as List<dynamic>? ?? const [];
  static double _double(dynamic value) => (value as num?)?.toDouble() ?? 0;
  static int _int(dynamic value) => (value as num?)?.toInt() ?? 0;
}

class WeatherCache {
  static const _key = 'last_weather_snapshot_v3';
  static const _legacyKey = 'last_weather_snapshot_v2';

  Future<void> save(WeatherSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, snapshot.encode());
  }

  Future<WeatherSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_key) ?? prefs.getString(_legacyKey);
      if (encoded == null) return null;
      return WeatherSnapshot.decode(encoded).copyWith(fromCache: true);
    } catch (_) {
      return null;
    }
  }
}
