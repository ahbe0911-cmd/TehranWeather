import 'dart:convert';

class GeoPointInfo {
  const GeoPointInfo({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.label,
    this.addressLine,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final String label;
  final String? addressLine;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'label': label,
        'addressLine': addressLine,
      };

  factory GeoPointInfo.fromJson(Map<String, dynamic> json) => GeoPointInfo(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        label: json['label'] as String? ?? 'موقعیت فعلی',
        addressLine: json['addressLine'] as String?,
      );
}

class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
    required this.cloudCover,
    required this.weatherCode,
    required this.isDay,
    required this.time,
  });

  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final double precipitation;
  final int cloudCover;
  final int weatherCode;
  final bool isDay;
  final DateTime time;

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'apparentTemperature': apparentTemperature,
        'humidity': humidity,
        'pressure': pressure,
        'windSpeed': windSpeed,
        'windDirection': windDirection,
        'precipitation': precipitation,
        'cloudCover': cloudCover,
        'weatherCode': weatherCode,
        'isDay': isDay,
        'time': time.toIso8601String(),
      };

  factory CurrentWeather.fromJson(Map<String, dynamic> json) => CurrentWeather(
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
        apparentTemperature:
            (json['apparentTemperature'] as num?)?.toDouble() ?? 0,
        humidity: (json['humidity'] as num?)?.toInt() ?? 0,
        pressure: (json['pressure'] as num?)?.toDouble() ?? 0,
        windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0,
        windDirection: (json['windDirection'] as num?)?.toDouble() ?? 0,
        precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0,
        cloudCover: (json['cloudCover'] as num?)?.toInt() ?? 0,
        weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
        isDay: json['isDay'] as bool? ?? true,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      );
}

class MinuteWeather {
  const MinuteWeather({
    required this.time,
    required this.precipitation,
    required this.weatherCode,
  });

  final DateTime time;
  final double precipitation;
  final int weatherCode;

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'precipitation': precipitation,
        'weatherCode': weatherCode,
      };

  factory MinuteWeather.fromJson(Map<String, dynamic> json) => MinuteWeather(
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0,
        weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
      );
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
  });

  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature': temperature,
        'precipitationProbability': precipitationProbability,
        'precipitation': precipitation,
        'weatherCode': weatherCode,
        'windSpeed': windSpeed,
      };

  factory HourlyWeather.fromJson(Map<String, dynamic> json) => HourlyWeather(
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
        precipitationProbability:
            (json['precipitationProbability'] as num?)?.toInt() ?? 0,
        precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0,
        weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
        windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0,
      );
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final int precipitationProbability;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'maxTemperature': maxTemperature,
        'minTemperature': minTemperature,
        'precipitationProbability': precipitationProbability,
        'weatherCode': weatherCode,
        'sunrise': sunrise.toIso8601String(),
        'sunset': sunset.toIso8601String(),
      };

  factory DailyWeather.fromJson(Map<String, dynamic> json) => DailyWeather(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        maxTemperature: (json['maxTemperature'] as num?)?.toDouble() ?? 0,
        minTemperature: (json['minTemperature'] as num?)?.toDouble() ?? 0,
        precipitationProbability:
            (json['precipitationProbability'] as num?)?.toInt() ?? 0,
        weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
        sunrise:
            DateTime.tryParse(json['sunrise'] as String? ?? '') ?? DateTime.now(),
        sunset:
            DateTime.tryParse(json['sunset'] as String? ?? '') ?? DateTime.now(),
      );
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.location,
    required this.current,
    required this.minutely,
    required this.hourly,
    required this.daily,
    required this.fetchedAt,
    this.fromCache = false,
  });

  final GeoPointInfo location;
  final CurrentWeather current;
  final List<MinuteWeather> minutely;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final DateTime fetchedAt;
  final bool fromCache;

  WeatherSnapshot copyWith({bool? fromCache}) => WeatherSnapshot(
        location: location,
        current: current,
        minutely: minutely,
        hourly: hourly,
        daily: daily,
        fetchedAt: fetchedAt,
        fromCache: fromCache ?? this.fromCache,
      );

  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'current': current.toJson(),
        'minutely': minutely.map((e) => e.toJson()).toList(),
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'daily': daily.map((e) => e.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) => WeatherSnapshot(
        location: GeoPointInfo.fromJson(
          (json['location'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        current: CurrentWeather.fromJson(
          (json['current'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        minutely: ((json['minutely'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => MinuteWeather.fromJson(e.cast<String, dynamic>()))
            .toList(),
        hourly: ((json['hourly'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => HourlyWeather.fromJson(e.cast<String, dynamic>()))
            .toList(),
        daily: ((json['daily'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => DailyWeather.fromJson(e.cast<String, dynamic>()))
            .toList(),
        fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  factory WeatherSnapshot.decode(String encoded) => WeatherSnapshot.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
}
