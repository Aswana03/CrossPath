import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Represents one GPS point recorded during a journey.
class JourneyPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  JourneyPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

/// Represents all the information required from one journey.
class JourneyData {
  final List<JourneyPoint> points;

  final double? destinationLatitude;
  final double? destinationLongitude;

  final DateTime startTime;
  final DateTime? endTime;

  final List<String> interests;

  JourneyData({
    required this.points,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.startTime,
    required this.endTime,
    required this.interests,
  });
}

/// Stores the individual matching scores.
class MatchScore {
  final double routeScore;
  final double destinationScore;
  final double crossingScore;
  final double interestScore;
  final double directionScore;
  final double timeScore;

  MatchScore({
    required this.routeScore,
    required this.destinationScore,
    required this.crossingScore,
    required this.interestScore,
    required this.directionScore,
    required this.timeScore,
  });

  /// Total score out of 100.
  double get totalScore {
    return routeScore +
        destinationScore +
        crossingScore +
        interestScore +
        directionScore +
        timeScore;
  }

  /// A CrossPath match requires at least 70 points.
  bool get isMatch {
    return totalScore >= 70;
  }
}

/// Main CrossPath matching service.
class MatchingService {

  // ------------------------------------------------------------
  // CROSSING SCORE
  // ------------------------------------------------------------

  double calculateCrossingScore(int crossingCount) {
    if (crossingCount <= 0) {
      return 0.0;
    }

    if (crossingCount == 1) {
      return 3.0;
    }

    if (crossingCount == 2) {
      return 8.0;
    }

    return 15.0;
  }
  // ------------------------------------------------------------
  // MATCHING CONSTANTS
  // ------------------------------------------------------------

  static const double routeMaximum = 35.0;
  static const double destinationMaximum = 25.0;
  static const double crossingMaximum = 15.0;
  static const double interestMaximum = 15.0;
  static const double directionMaximum = 5.0;
  static const double timeMaximum = 5.0;

  static const double matchThreshold = 70.0;

  // GPS distance used to determine whether two journey paths
  // are close enough to be considered overlapping.
  static const double routeOverlapRadius = 100.0;

  // ------------------------------------------------------------
  // DISTANCE BETWEEN TWO GPS POINTS
  // ------------------------------------------------------------

  double calculateDistance(
    JourneyPoint pointA,
    JourneyPoint pointB,
  ) {
    return Geolocator.distanceBetween(
      pointA.latitude,
      pointA.longitude,
      pointB.latitude,
      pointB.longitude,
    );
  }

  // ------------------------------------------------------------
// REPEATED CROSSING DETECTION
// ------------------------------------------------------------

  int detectCrossings(
    List<JourneyPoint> journeyA,
    List<JourneyPoint> journeyB,
  ) {
    if (journeyA.isEmpty || journeyB.isEmpty) {
      return 0;
    }

    bool insideCrossingZone = false;
    int crossingCount = 0;

    // Enter radius: users are considered close enough to cross
    // when they are within 100 metres.
    const double enterRadius = 100.0;

    // Exit radius is slightly larger to prevent GPS noise from
    // creating multiple false crossings.
    const double exitRadius = 150.0;

    for (final pointA in journeyA) {
      double minimumDistance = double.infinity;

      for (final pointB in journeyB) {
        final distance = calculateDistance(
          pointA,
          pointB,
        );

        if (distance < minimumDistance) {
          minimumDistance = distance;
        }
      }

      // ----------------------------------------------------------
      // ENTER CROSSING ZONE
      // ----------------------------------------------------------

      if (!insideCrossingZone &&
          minimumDistance <= enterRadius) {
        crossingCount++;
        insideCrossingZone = true;
      }

      // ----------------------------------------------------------
      // EXIT CROSSING ZONE
      // ----------------------------------------------------------

      else if (insideCrossingZone &&
          minimumDistance > exitRadius) {
        insideCrossingZone = false;
      }
    }

    return crossingCount;
  }

  // ------------------------------------------------------------
  // ROUTE OVERLAP CALCULATION
  // ------------------------------------------------------------

  double calculateRouteOverlap(
    List<JourneyPoint> journeyA,
    List<JourneyPoint> journeyB,
  ) {
    if (journeyA.isEmpty || journeyB.isEmpty) {
      return 0.0;
    }

    // Check how many points from Journey A
    // are within 100 metres of Journey B.
    int overlappingA = 0;

    for (final pointA in journeyA) {
      bool foundOverlap = false;

      for (final pointB in journeyB) {
        final distance = calculateDistance(
          pointA,
          pointB,
        );

        if (distance <= routeOverlapRadius) {
          foundOverlap = true;
          break;
        }
      }

      if (foundOverlap) {
        overlappingA++;
      }
    }

    // Check how many points from Journey B
    // are within 100 metres of Journey A.
    int overlappingB = 0;

    for (final pointB in journeyB) {
      bool foundOverlap = false;

      for (final pointA in journeyA) {
        final distance = calculateDistance(
          pointB,
          pointA,
        );

        if (distance <= routeOverlapRadius) {
          foundOverlap = true;
          break;
        }
      }

      if (foundOverlap) {
        overlappingB++;
      }
    }

    // Calculate overlap ratio for both journeys.
    final ratioA = overlappingA / journeyA.length;
    final ratioB = overlappingB / journeyB.length;

    // Give equal importance to both journeys.
    final symmetricOverlap = (ratioA + ratioB) / 2.0;

    // Convert the overlap ratio to a score out of 35.
    return symmetricOverlap * routeMaximum;
  }

    // ------------------------------------------------------------
  // DESTINATION AREA SCORE
  // ------------------------------------------------------------

  double calculateDestinationScore(
    JourneyData journeyA,
    JourneyData journeyB,
  ) {
    // If either journey does not have destination coordinates,
    // destination matching cannot be calculated.
    if (journeyA.destinationLatitude == null ||
        journeyA.destinationLongitude == null ||
        journeyB.destinationLatitude == null ||
        journeyB.destinationLongitude == null) {
      return 0.0;
    }

    // Calculate the distance between the two destinations.
    final destinationDistance = Geolocator.distanceBetween(
      journeyA.destinationLatitude!,
      journeyA.destinationLongitude!,
      journeyB.destinationLatitude!,
      journeyB.destinationLongitude!,
    );

    // ----------------------------------------------------------
    // DESTINATION SCORING
    // ----------------------------------------------------------

    // Same / very nearby destination.
    if (destinationDistance <= 1000) {
      return destinationMaximum;
    }

    // Within 3 km.
    if (destinationDistance <= 3000) {
      return 20.0;
    }

    // Within 5 km.
    if (destinationDistance <= 5000) {
      return 15.0;
    }

    // Within 10 km.
    if (destinationDistance <= 10000) {
      return 8.0;
    }

    // More than 10 km apart.
    return 0.0;
  }

    // ------------------------------------------------------------
  // INTEREST MATCHING
  // ------------------------------------------------------------

  double calculateInterestScore(
    List<String> interestsA,
    List<String> interestsB,
  ) {
    if (interestsA.isEmpty || interestsB.isEmpty) {
      return 0.0;
    }

    // Convert interests to lowercase so that
    // "Music" and "music" are treated as the same.
    final setA = interestsA
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();

    final setB = interestsB
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();

    if (setA.isEmpty || setB.isEmpty) {
      return 0.0;
    }

    // Find common interests.
    final commonInterests = setA.intersection(setB);

    // Jaccard similarity:
    // common interests / total unique interests.
    final unionInterests = setA.union(setB);

    final similarity =
        commonInterests.length / unionInterests.length;

    // Convert similarity to a score out of 15.
    return similarity * interestMaximum;
  }

    // ------------------------------------------------------------
  // DIRECTION SCORE
  // ------------------------------------------------------------

  double calculateDirectionScore(
    List<JourneyPoint> journeyA,
    List<JourneyPoint> journeyB,
  ) {
    // At least two points are required to determine
    // the direction of travel.
    if (journeyA.length < 2 || journeyB.length < 2) {
      return 0.0;
    }

    final bearingA = _calculateBearing(
      journeyA.first,
      journeyA.last,
    );

    final bearingB = _calculateBearing(
      journeyB.first,
      journeyB.last,
    );

    // Calculate the smallest angular difference.
    double difference = (bearingA - bearingB).abs();

    if (difference > 180) {
      difference = 360 - difference;
    }

    // ----------------------------------------------------------
    // DIRECTION SCORING
    // ----------------------------------------------------------

    // Almost exactly the same direction.
    if (difference <= 30) {
      return directionMaximum;
    }

    // Generally travelling in the same direction.
    if (difference <= 60) {
      return 3.0;
    }

    // Some directional similarity.
    if (difference <= 90) {
      return 1.0;
    }

    // Opposite / significantly different direction.
    return 0.0;
  }

  // ------------------------------------------------------------
  // CALCULATE BEARING BETWEEN TWO GPS POINTS
  // ------------------------------------------------------------

  double _calculateBearing(
    JourneyPoint start,
    JourneyPoint end,
  ) {
    final startLatitude =
        start.latitude * 3.141592653589793 / 180;

    final endLatitude =
        end.latitude * 3.141592653589793 / 180;

    final longitudeDifference =
        (end.longitude - start.longitude) *
            3.141592653589793 /
            180;

        final y = math.sin(longitudeDifference) *
        math.cos(endLatitude);

    final x =
        math.cos(startLatitude) *
                math.sin(endLatitude) -
            math.sin(startLatitude) *
                math.cos(endLatitude) *
                math.cos(longitudeDifference);

    var bearing =
        math.atan2(y, x) * 180 / 3.141592653589793;

    bearing = (bearing + 360) % 360;

    return bearing;
  }

    // ------------------------------------------------------------
  // TIME OVERLAP SCORE
  // ------------------------------------------------------------

  double calculateTimeScore(
    JourneyData journeyA,
    JourneyData journeyB,
  ) {
    // Both journeys need an end time.
    if (journeyA.endTime == null ||
        journeyB.endTime == null) {
      return 0.0;
    }

    final startA = journeyA.startTime;
    final endA = journeyA.endTime!;

    final startB = journeyB.startTime;
    final endB = journeyB.endTime!;

    // Find when the overlapping period starts.
    final overlapStart =
        startA.isAfter(startB) ? startA : startB;

    // Find when the overlapping period ends.
    final overlapEnd =
        endA.isBefore(endB) ? endA : endB;

    // No overlap.
    if (!overlapEnd.isAfter(overlapStart)) {
      return 0.0;
    }

    // Duration of the overlapping period.
    final overlapDuration =
        overlapEnd.difference(overlapStart);

    // Calculate the duration of each journey.
    final durationA = endA.difference(startA);
    final durationB = endB.difference(startB);

    // Use the shorter journey as the reference.
    final shorterDuration =
        durationA < durationB ? durationA : durationB;

    if (shorterDuration.inSeconds <= 0) {
      return 0.0;
    }

    // Calculate how much of the shorter journey
    // occurred at the same time as the other journey.
    final overlapRatio =
        overlapDuration.inSeconds /
            shorterDuration.inSeconds;

    // Convert to a score out of 5.
    return overlapRatio.clamp(0.0, 1.0) * timeMaximum;
  }

    // ------------------------------------------------------------
  // COMPLETE MATCHING SCORE
  // ------------------------------------------------------------

  MatchScore calculateMatchScore(
    JourneyData journeyA,
    JourneyData journeyB,
  ) {
    // 1. Route overlap → 35 points
    final routeScore = calculateRouteOverlap(
      journeyA.points,
      journeyB.points,
    );

    // 2. Destination area → 25 points
    final destinationScore = calculateDestinationScore(
      journeyA,
      journeyB,
    );

    // 3. Repeated crossings → 15 points
    final crossingCount = detectCrossings(
      journeyA.points,
      journeyB.points,
    );

    final crossingScore =
        calculateCrossingScore(crossingCount);

    // 4. Common interests → 15 points
    final interestScore = calculateInterestScore(
      journeyA.interests,
      journeyB.interests,
    );

    // 5. Travel direction → 5 points
    final directionScore = calculateDirectionScore(
      journeyA.points,
      journeyB.points,
    );

    // 6. Time overlap → 5 points
    final timeScore = calculateTimeScore(
      journeyA,
      journeyB,
    );

    // Return all individual scores together.
    return MatchScore(
      routeScore: routeScore,
      destinationScore: destinationScore,
      crossingScore: crossingScore,
      interestScore: interestScore,
      directionScore: directionScore,
      timeScore: timeScore,
    );
  }
}