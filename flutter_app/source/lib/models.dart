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
        temperature: (json['temperature'] as num).toDouble(),
        apparentTemperature: (json['apparentTemperature'] as num).toDouble(),
        humidity: (json['humidity'] as num).toInt(),
        pressure: (json['pressure'] as num).toDouble(),
        windSpeed: (json['windSpeed'] as num).toDouble(),
        windDirection: (json['windDirection'] as num).toDouble(),
        precipitation: (json['precipitation'] as num).toDouble(),
        cloudCover: (json['cloudCover'] as num).toInt(),
        weatherCode: (json['weatherCode'] as num).toInt(),
        isDay: json['isDay'] as bool,
        time: DateTime.parse(json['time'] as String),
      );
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.windSpeed,
  });

  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;
  final double windSpeed;

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature': temperature,
        'precipitationProbability': precipitationProbability,
        'weatherCode': weatherCode,
        'windSpeed': windSpeed,
      };

  factory HourlyWeather.fromJson(Map<String, dynamic> json) => HourlyWeather(
        time: DateTime.parse(json['time'] as String),
        temperature: (json['temperature'] as num).toDouble(),
        precipitationProbability:
            (json['precipitationProbability'] as num).toInt(),
        weatherCode: (json['weatherCode'] as num).toInt(),
        windSpeed: (json['windSpeed'] as num).toDouble(),
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
        date: DateTime.parse(json['date'] as String),
        maxTemperature: (json['maxTemperature'] as num).toDouble(),
        minTemperature: (json['minTemperature'] as num).toDouble(),
        precipitationProbability:
            (json['precipitationProbability'] as num).toInt(),
        weatherCode: (json['weatherCode'] as num).toInt(),
        sunrise: DateTime.parse(json['sunrise'] as String),
        sunset: DateTime.parse(json['sunset'] as String),
      );
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.location,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.fetchedAt,
    this.fromCache = false,
  });

  final GeoPointInfo location;
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final DateTime fetchedAt;
  final bool fromCache;

  WeatherSnapshot copyWith({bool? fromCache}) => WeatherSnapshot(
        location: location,
        current: current,
        hourly: hourly,
        daily: daily,
        fetchedAt: fetchedAt,
        fromCache: fromCache ?? this.fromCache,
      );

  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'current': current.toJson(),
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'daily': daily.map((e) => e.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) => WeatherSnapshot(
        location:
            GeoPointInfo.fromJson(json['location'] as Map<String, dynamic>),
        current:
            CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
        hourly: (json['hourly'] as List<dynamic>)
            .map((e) => HourlyWeather.fromJson(e as Map<String, dynamic>))
            .toList(),
        daily: (json['daily'] as List<dynamic>)
            .map((e) => DailyWeather.fromJson(e as Map<String, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  factory WeatherSnapshot.decode(String encoded) => WeatherSnapshot.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
}
