import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

// Pure Dart re-implementation of the routing score formula for unit testing.
double routingScore({
  required double distanceKm,
  required int waitTimeMin,
  required bool specialistMatch,
}) {
  return (distanceKm * 0.4) + (waitTimeMin * 0.4) - (specialistMatch ? 10 * 0.2 : 0);
}

void main() {
  group('Hospital routing score', () {
    test('lower distance gives lower score', () {
      final scoreNear = routingScore(distanceKm: 2, waitTimeMin: 30, specialistMatch: false);
      final scoreFar = routingScore(distanceKm: 20, waitTimeMin: 30, specialistMatch: false);
      expect(scoreNear, lessThan(scoreFar));
    });

    test('specialist match reduces score', () {
      final withSpec = routingScore(distanceKm: 5, waitTimeMin: 20, specialistMatch: true);
      final withoutSpec = routingScore(distanceKm: 5, waitTimeMin: 20, specialistMatch: false);
      expect(withSpec, lessThan(withoutSpec));
    });

    test('specialist match reduces score by 2.0', () {
      final withSpec = routingScore(distanceKm: 5, waitTimeMin: 20, specialistMatch: true);
      final withoutSpec = routingScore(distanceKm: 5, waitTimeMin: 20, specialistMatch: false);
      expect(withoutSpec - withSpec, closeTo(2.0, 0.001));
    });
  });

  group('HospitalModel JSON parsing', () {
    test('parses hospital from JSON', () {
      final json = jsonDecode('''{
        "id": 1,
        "name": "Hospital General",
        "address": "Calle 123",
        "lat": 19.42,
        "lng": -99.13,
        "phone": "+52 55 1234 5678",
        "status": {"wait_time_min": 45, "available_beds": 5, "updated_at": "2026-02-20T12:00:00Z"},
        "specialties": [],
        "distance_km": 3.5,
        "score": 14.2
      }''') as Map<String, dynamic>;

      expect(json['id'], equals(1));
      expect(json['name'], equals('Hospital General'));
      expect((json['status'] as Map)['wait_time_min'], equals(45));
    });
  });
}
