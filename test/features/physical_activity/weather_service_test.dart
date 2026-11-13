import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meditrackmobile/features/auth/models/user.dart';
import 'package:meditrackmobile/features/physical_activity/models/weather_data.dart';
import 'package:meditrackmobile/features/physical_activity/services/activity_recommendation_service.dart';
import 'package:meditrackmobile/features/physical_activity/services/weather_service.dart';

void main() {
  group('WeatherData Model Tests', () {
    test('Interpretation of Open-Meteo WMO weather codes', () {
      final sunny = WeatherData(
        temperature: 22.0,
        apparentTemperature: 22.0,
        weatherCode: 0,
        precipitation: 0.0,
        windSpeed: 10.0,
        humidity: 45,
        timestamp: DateTime(2026, 11, 13),
      );
      expect(sunny.weatherDescription, 'Clear Sky');
      expect(sunny.isOutdoorFriendly, isTrue);
      expect(sunny.isRainy, isFalse);

      final rainy = WeatherData(
        temperature: 14.0,
        apparentTemperature: 13.0,
        weatherCode: 63, // Moderate rain
        precipitation: 3.5,
        windSpeed: 15.0,
        humidity: 90,
        timestamp: DateTime(2026, 11, 13),
      );
      expect(rainy.weatherDescription, 'Rainy');
      expect(rainy.isOutdoorFriendly, isFalse);
      expect(rainy.isRainy, isTrue);
      expect(rainy.recommendedSports.contains('Swimming'), isTrue);

      final stormy = WeatherData(
        temperature: 18.0,
        apparentTemperature: 18.0,
        weatherCode: 95, // Thunderstorm
        precipitation: 10.0,
        windSpeed: 45.0,
        humidity: 95,
        timestamp: DateTime(2026, 11, 13),
      );
      expect(stormy.weatherDescription, 'Thunderstorm');
      expect(stormy.isStormy, isTrue);
      expect(stormy.isOutdoorFriendly, isFalse);
      expect(stormy.weatherSportAdvice, contains('Thunderstorm risk'));

      final hot = WeatherData(
        temperature: 32.0,
        apparentTemperature: 35.0,
        weatherCode: 1,
        precipitation: 0.0,
        windSpeed: 8.0,
        humidity: 60,
        timestamp: DateTime(2026, 11, 13),
      );
      expect(hot.isHot, isTrue);
      expect(hot.weatherSportAdvice, contains('High temperature'));

      final cold = WeatherData(
        temperature: 2.0,
        apparentTemperature: 0.0,
        weatherCode: 2,
        precipitation: 0.0,
        windSpeed: 12.0,
        humidity: 70,
        timestamp: DateTime(2026, 11, 13),
      );
      expect(cold.isFreezing, isTrue);
      expect(cold.weatherSportAdvice, contains('Chilly weather'));
    });

    test('Serialization toMap() / fromMap() of WeatherData', () {
      final now = DateTime(2026, 11, 13, 10, 0);
      final weather = WeatherData(
        temperature: 19.5,
        apparentTemperature: 19.0,
        weatherCode: 2,
        precipitation: 0.2,
        windSpeed: 14.0,
        humidity: 65,
        timestamp: now,
        cityName: 'Paris',
      );

      final map = weather.toMap();
      expect(map['temperature'], 19.5);
      expect(map['weather_code'], 2);
      expect(map['city_name'], 'Paris');

      final reconstructed = WeatherData.fromMap(map);
      expect(reconstructed.temperature, 19.5);
      expect(reconstructed.weatherCode, 2);
      expect(reconstructed.cityName, 'Paris');
    });

    test('fromOpenMeteoJson() parses standard Open-Meteo payload', () {
      final json = {
        'latitude': 48.85,
        'longitude': 2.35,
        'current': {
          'temperature_2m': 21.4,
          'apparent_temperature': 20.8,
          'weather_code': 1,
          'precipitation': 0.0,
          'wind_speed_10m': 12.5,
          'relative_humidity_2m': 55,
        }
      };

      final weather = WeatherData.fromOpenMeteoJson(json, cityName: 'Test Area');
      expect(weather.temperature, 21.4);
      expect(weather.apparentTemperature, 20.8);
      expect(weather.weatherCode, 1);
      expect(weather.windSpeed, 12.5);
      expect(weather.humidity, 55);
      expect(weather.cityName, 'Test Area');
    });
  });

  group('Weather-Based Recommendation Engine Tests', () {
    final service = ActivityRecommendationService.instance;

    test('Generates indoor recommendation on rainy weather', () {
      final rainy = WeatherData(
        temperature: 15.0,
        apparentTemperature: 14.0,
        weatherCode: 61, // Rain
        precipitation: 2.5,
        windSpeed: 10.0,
        humidity: 85,
        timestamp: DateTime(2026, 11, 13),
      );

      final rec = service.generateWeatherRecommendation(weather: rainy);
      expect(rec.category, 'Weather-Adaptive Session');
      expect(rec.activityType, 'Swimming');
      expect(rec.title, contains('Indoor Swimming'));
    });

    test('Generates sheltered gentle workout on severe storm', () {
      final stormy = WeatherData(
        temperature: 16.0,
        apparentTemperature: 15.0,
        weatherCode: 95, // Storm
        precipitation: 15.0,
        windSpeed: 50.0,
        humidity: 95,
        timestamp: DateTime(2026, 11, 13),
      );

      final rec = service.generateWeatherRecommendation(weather: stormy);
      expect(rec.activityType, 'Other');
      expect(rec.intensity, 'Low');
      expect(rec.title, contains('Indoor'));
    });

    test('Generates outdoor cycling on optimal clear weather', () {
      final sunny = WeatherData(
        temperature: 20.0,
        apparentTemperature: 20.0,
        weatherCode: 0,
        precipitation: 0.0,
        windSpeed: 10.0,
        humidity: 50,
        timestamp: DateTime(2026, 11, 13),
      );

      final rec = service.generateWeatherRecommendation(weather: sunny);
      expect(rec.activityType, 'Cycling');
      expect(rec.title, contains('Outdoor'));
      expect(rec.intensity, 'Moderate');
    });

    test('Includes medical notice for patient with reported condition', () {
      final sunny = WeatherData(
        temperature: 20.0,
        apparentTemperature: 20.0,
        weatherCode: 0,
        precipitation: 0.0,
        windSpeed: 10.0,
        humidity: 50,
        timestamp: DateTime(2026, 11, 13),
      );

      final userWithCondition = User(
        nom: 'Martin',
        prenom: 'Paul',
        email: 'paul.martin@meditrack.fr',
        conditionMedicale: 'Asthma',
      );

      final rec = service.generateWeatherRecommendation(
        weather: sunny,
        user: userWithCondition,
      );

      expect(rec.medicalAdvice, isNotNull);
      expect(rec.medicalAdvice, contains('Asthma'));
      expect(rec.intensity, 'Low'); // Capped intensity for medical safety
    });
  });

  group('WeatherService Network & Cache Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      WeatherService.instance.clearCache();
    });

    test('Consumes Open-Meteo API successfully with MockClient (Status 200)', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        final response = {
          'current': {
            'temperature_2m': 18.5,
            'apparent_temperature': 18.0,
            'weather_code': 2,
            'precipitation': 0.0,
            'wind_speed_10m': 11.0,
            'relative_humidity_2m': 60,
          }
        };
        return http.Response(jsonEncode(response), 200, headers: {'content-type': 'application/json'});
      });

      final service = WeatherService.instance;
      final weather = await service.getCurrentWeather(forceRefresh: true, client: mockClient);

      expect(weather.temperature, 18.5);
      expect(weather.weatherCode, 2);
      expect(weather.weatherDescription, 'Partly Cloudy');
    });

    test('Returns reliable fallback on network failure (Status 500)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = WeatherService.instance;
      final weather = await service.getCurrentWeather(forceRefresh: true, client: mockClient);

      expect(weather, isNotNull);
      expect(weather.temperature > 0, isTrue);
    });

    test('Caches weather data and avoids duplicate network requests', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        final response = {
          'current': {
            'temperature_2m': 22.0,
            'apparent_temperature': 22.0,
            'weather_code': 0,
            'precipitation': 0.0,
            'wind_speed_10m': 8.0,
            'relative_humidity_2m': 50,
          }
        };
        return http.Response(jsonEncode(response), 200, headers: {'content-type': 'application/json'});
      });

      final service = WeatherService.instance;
      await service.clearCache();

      // 1er appel : requête réseau
      final first = await service.getCurrentWeather(forceRefresh: true, client: mockClient);
      expect(requestCount, 1);
      expect(first.temperature, 22.0);

      // 2e appel : appel normal sans forceRefresh -> chargé depuis le cache
      final second = await service.getCurrentWeather(forceRefresh: false, client: mockClient);
      expect(requestCount, 1); // Pas d'appel réseau supplémentaire
      expect(second.temperature, first.temperature);

      // 3e appel : forcé -> nouvelle requête réseau
      await service.getCurrentWeather(forceRefresh: true, client: mockClient);
      expect(requestCount, 2);
    });
  });
}
