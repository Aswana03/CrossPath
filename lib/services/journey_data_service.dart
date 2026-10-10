import 'package:cloud_firestore/cloud_firestore.dart';

import 'matching_service.dart';

class JourneyDataService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // LOAD A USER'S JOURNEY
  // ------------------------------------------------------------

  Future<JourneyData?> loadJourneyData({
    required String userId,
    required String journeyId,
  }) async {
    // ----------------------------------------------------------
    // LOAD JOURNEY DOCUMENT
    // ----------------------------------------------------------

    final journeySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('journeys')
        .doc(journeyId)
        .get();

    if (!journeySnapshot.exists) {
      return null;
    }

    final journeyData = journeySnapshot.data();

    if (journeyData == null) {
      return null;
    }

    // ----------------------------------------------------------
    // READ DESTINATION
    // ----------------------------------------------------------

    final destinationLatitude =
        (journeyData['destinationLatitude'] as num?)?.toDouble();

    final destinationLongitude =
        (journeyData['destinationLongitude'] as num?)?.toDouble();

    // ----------------------------------------------------------
    // READ START TIME
    // ----------------------------------------------------------

    final startTimestamp =
        journeyData['startTime'] as Timestamp?;

    if (startTimestamp == null) {
      return null;
    }

    final startTime = startTimestamp.toDate();

    // ----------------------------------------------------------
    // READ END TIME
    // ----------------------------------------------------------

    final endTimestamp =
        journeyData['endTime'] as Timestamp?;

    final endTime = endTimestamp?.toDate();

    // ----------------------------------------------------------
    // LOAD GPS POINTS
    // ----------------------------------------------------------

    final pointsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('journeys')
        .doc(journeyId)
        .collection('points')
        .orderBy('timestamp')
        .get();

    final points = <JourneyPoint>[];

    for (final pointDocument in pointsSnapshot.docs) {
      final pointData = pointDocument.data();

      final latitude =
          (pointData['latitude'] as num?)?.toDouble();

      final longitude =
          (pointData['longitude'] as num?)?.toDouble();

      final timestamp =
          pointData['timestamp'] as Timestamp?;

      if (latitude == null ||
          longitude == null ||
          timestamp == null) {
        continue;
      }

      points.add(
        JourneyPoint(
          latitude: latitude,
          longitude: longitude,
          timestamp: timestamp.toDate(),
        ),
      );
    }

    // ----------------------------------------------------------
    // LOAD USER PROFILE
    // ----------------------------------------------------------

    final userSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    if (!userSnapshot.exists) {
      return null;
    }

    final userData = userSnapshot.data();

    if (userData == null) {
      return null;
    }

    // ----------------------------------------------------------
    // READ INTERESTS
    // ----------------------------------------------------------

    final interestsData = userData['interests'];

    final interests = <String>[];

    if (interestsData is List) {
      for (final interest in interestsData) {
        if (interest is String) {
          interests.add(interest);
        }
      }
    }

    // ----------------------------------------------------------
    // CREATE JOURNEY DATA
    // ----------------------------------------------------------

    return JourneyData(
      points: points,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      startTime: startTime,
      endTime: endTime,
      interests: interests,
    );
  }
}