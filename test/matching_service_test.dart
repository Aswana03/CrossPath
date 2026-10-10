import 'package:flutter_test/flutter_test.dart';
import 'package:crosspath/services/matching_service.dart';

void main() {
  test('CrossPath matching algorithm test', () {
    final service = MatchingService();

    // ----------------------------------------------------------
    // FAKE JOURNEY A
    // ----------------------------------------------------------

    final journeyA = JourneyData(
      points: [
        JourneyPoint(
          latitude: 11.2588,
          longitude: 75.7804,
          timestamp: DateTime(2026, 10, 11, 10, 0),
        ),
        JourneyPoint(
          latitude: 11.2600,
          longitude: 75.7820,
          timestamp: DateTime(2026, 10, 11, 10, 10),
        ),
        JourneyPoint(
          latitude: 11.2620,
          longitude: 75.7840,
          timestamp: DateTime(2026, 10, 11, 10, 20),
        ),
      ],
      destinationLatitude: 11.2700,
      destinationLongitude: 75.7900,
      startTime: DateTime(2026, 10, 11, 10, 0),
      endTime: DateTime(2026, 10, 11, 11, 0),
      interests: [
        'Travel',
        'Music',
        'Photography',
      ],
    );

    // ----------------------------------------------------------
    // FAKE JOURNEY B
    // ----------------------------------------------------------

    final journeyB = JourneyData(
      points: [
        JourneyPoint(
          latitude: 11.2589,
          longitude: 75.7805,
          timestamp: DateTime(2026, 10, 11, 10, 5),
        ),
        JourneyPoint(
          latitude: 11.2601,
          longitude: 75.7821,
          timestamp: DateTime(2026, 10, 11, 10, 15),
        ),
        JourneyPoint(
          latitude: 11.2621,
          longitude: 75.7841,
          timestamp: DateTime(2026, 10, 11, 10, 25),
        ),
      ],
      destinationLatitude: 11.2710,
      destinationLongitude: 75.7910,
      startTime: DateTime(2026, 10, 11, 10, 5),
      endTime: DateTime(2026, 10, 11, 10, 55),
      interests: [
        'Travel',
        'Music',
        'Gaming',
      ],
    );

    // ----------------------------------------------------------
    // CALCULATE MATCH
    // ----------------------------------------------------------

    final result = service.calculateMatchScore(
      journeyA,
      journeyB,
    );

    // ----------------------------------------------------------
    // PRINT RESULTS
    // ----------------------------------------------------------

    print('========================================');
    print('       CROSSPATH MATCHING TEST');
    print('========================================');

    print(
      'Route Score:       '
      '${result.routeScore.toStringAsFixed(2)} / 35',
    );

    print(
      'Destination Score: '
      '${result.destinationScore.toStringAsFixed(2)} / 25',
    );

    print(
      'Crossing Score:    '
      '${result.crossingScore.toStringAsFixed(2)} / 15',
    );

    print(
      'Interest Score:    '
      '${result.interestScore.toStringAsFixed(2)} / 15',
    );

    print(
      'Direction Score:   '
      '${result.directionScore.toStringAsFixed(2)} / 5',
    );

    print(
      'Time Score:        '
      '${result.timeScore.toStringAsFixed(2)} / 5',
    );

    print('----------------------------------------');

    print(
      'TOTAL SCORE:       '
      '${result.totalScore.toStringAsFixed(2)} / 100',
    );

    print(
      'MATCH:             '
      '${result.isMatch ? "YES" : "NO"}',
    );

    print('========================================');

    // Basic sanity checks.
    expect(result.routeScore, greaterThan(0));
    expect(result.destinationScore, greaterThan(0));
    expect(result.crossingScore, greaterThan(0));
    expect(result.interestScore, greaterThan(0));
    expect(result.directionScore, greaterThan(0));
    expect(result.timeScore, greaterThan(0));

    expect(result.totalScore, greaterThan(0));
  });

    test('CrossPath non-match test', () {
    final service = MatchingService();

    // ----------------------------------------------------------
    // FAKE JOURNEY A
    // ----------------------------------------------------------

    final journeyA = JourneyData(
      points: [
        JourneyPoint(
          latitude: 11.2588,
          longitude: 75.7804,
          timestamp: DateTime(2026, 10, 11, 10, 0),
        ),
        JourneyPoint(
          latitude: 11.2600,
          longitude: 75.7820,
          timestamp: DateTime(2026, 10, 11, 10, 10),
        ),
        JourneyPoint(
          latitude: 11.2620,
          longitude: 75.7840,
          timestamp: DateTime(2026, 10, 11, 10, 20),
        ),
      ],
      destinationLatitude: 11.2700,
      destinationLongitude: 75.7900,
      startTime: DateTime(2026, 10, 11, 10, 0),
      endTime: DateTime(2026, 10, 11, 11, 0),
      interests: [
        'Travel',
        'Music',
      ],
    );

    // ----------------------------------------------------------
    // FAKE JOURNEY B
    // Completely different route/destination/interests/time.
    // ----------------------------------------------------------

    final journeyB = JourneyData(
      points: [
        JourneyPoint(
          latitude: 11.3500,
          longitude: 75.9000,
          timestamp: DateTime(2026, 10, 11, 18, 0),
        ),
        JourneyPoint(
          latitude: 11.3600,
          longitude: 75.9100,
          timestamp: DateTime(2026, 10, 11, 18, 10),
        ),
        JourneyPoint(
          latitude: 11.3700,
          longitude: 75.9200,
          timestamp: DateTime(2026, 10, 11, 18, 20),
        ),
      ],
      destinationLatitude: 11.5000,
      destinationLongitude: 76.0000,
      startTime: DateTime(2026, 10, 11, 18, 0),
      endTime: DateTime(2026, 10, 11, 19, 0),
      interests: [
        'Gaming',
        'Cooking',
      ],
    );

    // ----------------------------------------------------------
    // CALCULATE MATCH
    // ----------------------------------------------------------

    final result = service.calculateMatchScore(
      journeyA,
      journeyB,
    );

    // ----------------------------------------------------------
    // PRINT RESULTS
    // ----------------------------------------------------------

    print('========================================');
    print('       CROSSPATH NON-MATCH TEST');
    print('========================================');

    print(
      'Route Score:       '
      '${result.routeScore.toStringAsFixed(2)} / 35',
    );

    print(
      'Destination Score: '
      '${result.destinationScore.toStringAsFixed(2)} / 25',
    );

    print(
      'Crossing Score:    '
      '${result.crossingScore.toStringAsFixed(2)} / 15',
    );

    print(
      'Interest Score:    '
      '${result.interestScore.toStringAsFixed(2)} / 15',
    );

    print(
      'Direction Score:   '
      '${result.directionScore.toStringAsFixed(2)} / 5',
    );

    print(
      'Time Score:        '
      '${result.timeScore.toStringAsFixed(2)} / 5',
    );

    print('----------------------------------------');

    print(
      'TOTAL SCORE:       '
      '${result.totalScore.toStringAsFixed(2)} / 100',
    );

    print(
      'MATCH:             '
      '${result.isMatch ? "YES" : "NO"}',
    );

    print('========================================');

    // This journey pair should NOT be a match.
    expect(result.totalScore, lessThan(70));
    expect(result.isMatch, false);
  });
}

