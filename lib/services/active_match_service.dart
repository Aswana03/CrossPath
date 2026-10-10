import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'journey_data_service.dart';
import 'matching_service.dart';

class ActiveMatch {
  final String userId;
  final String journeyId;
  final MatchScore score;

  ActiveMatch({
    required this.userId,
    required this.journeyId,
    required this.score,
  });
}

class ActiveMatchService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final JourneyDataService _journeyDataService =
      JourneyDataService();

  Future<List<ActiveMatch>> findActiveMatches({
    required String myJourneyId,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }

    // 1. Load my active journey.
    final myJourney =
        await _journeyDataService.loadJourneyData(
      userId: currentUser.uid,
      journeyId: myJourneyId,
    );

    if (myJourney == null) {
      throw Exception('My journey could not be loaded.');
    }

    // 2. Find users who are discoverable.
    final usersSnapshot = await _firestore
        .collection('users')
        .where('discoverable', isEqualTo: true)
        .get();

    final matches = <ActiveMatch>[];

    // 3. Check every discoverable user.
    for (final userDocument in usersSnapshot.docs) {
      final otherUserId = userDocument.id;

      // Never compare with ourselves.
      if (otherUserId == currentUser.uid) {
        continue;
      }

      // 4. Find their active journeys.
      final journeysSnapshot = await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('journeys')
          .where('status', isEqualTo: 'active')
          .get();

      for (final journeyDocument in journeysSnapshot.docs) {
        final otherJourneyId = journeyDocument.id;

        // 5. Load the other person's journey.
        final otherJourney =
            await _journeyDataService.loadJourneyData(
          userId: otherUserId,
          journeyId: otherJourneyId,
        );

        if (otherJourney == null) {
          continue;
        }

        // 6. Calculate the CrossPath score.
        final score =
            MatchingService().calculateMatchScore(
          myJourney,
          otherJourney,
        );

        // 7. Keep only scores >= 70.
        if (score.isMatch) {
          matches.add(
            ActiveMatch(
              userId: otherUserId,
              journeyId: otherJourneyId,
              score: score,
            ),
          );
        }
      }
    }

    // 8. Highest score first.
    matches.sort(
      (a, b) => b.score.totalScore.compareTo(
        a.score.totalScore,
      ),
    );

    return matches;
  }
}