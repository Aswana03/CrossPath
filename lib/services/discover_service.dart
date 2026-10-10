import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscoverResult {
  final String discoveryId;
  final bool iDiscovered;
  final bool otherUserDiscovered;
  final bool isMutual;

  DiscoverResult({
    required this.discoveryId,
    required this.iDiscovered,
    required this.otherUserDiscovered,
    required this.isMutual,
  });
}

class DiscoverService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  /// Creates a consistent ID for the two users.
  ///
  /// Sorting the UIDs ensures that:
  /// A + B
  /// and
  /// B + A
  /// produce the same discovery document.
  String createDiscoveryId(
    String userA,
    String userB,
  ) {
    final users = [userA, userB]..sort();
    return '${users[0]}_${users[1]}';
  }

  /// Get the current discovery state between two users.
  Future<DiscoverResult?> getDiscovery({
    required String otherUserId,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }

    final discoveryId = createDiscoveryId(
      currentUser.uid,
      otherUserId,
    );

    final document = await _firestore
        .collection('discoveries')
        .doc(discoveryId)
        .get();

    if (!document.exists) {
      return null;
    }

    final data = document.data()!;

    final userA = data['userA'] as String;
    final userB = data['userB'] as String;

    final currentUserIsA =
        currentUser.uid == userA;

    final iDiscovered = currentUserIsA
        ? data['userADiscovered'] == true
        : data['userBDiscovered'] == true;

    final otherUserDiscovered = currentUserIsA
        ? data['userBDiscovered'] == true
        : data['userADiscovered'] == true;

    return DiscoverResult(
      discoveryId: discoveryId,
      iDiscovered: iDiscovered,
      otherUserDiscovered: otherUserDiscovered,
      isMutual: iDiscovered && otherUserDiscovered,
    );
  }

  /// Record that the current user chose DISCOVER.
  Future<DiscoverResult> discover({
    required String otherUserId,
    required String journeyId,
    required double score,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }

    final currentUserId = currentUser.uid;

    final discoveryId = createDiscoveryId(
      currentUserId,
      otherUserId,
    );

    final documentReference = _firestore
        .collection('discoveries')
        .doc(discoveryId);

    final existingDocument =
        await documentReference.get();

    if (!existingDocument.exists) {
      final users = [
        currentUserId,
        otherUserId,
      ]..sort();

      final userA = users[0];
      final userB = users[1];

      await documentReference.set({
        'userA': userA,
        'userB': userB,
        'journeyA': userA == currentUserId
            ? journeyId
            : null,
        'journeyB': userB == currentUserId
            ? journeyId
            : null,
        'score': score,
        'userADiscovered': userA == currentUserId,
        'userBDiscovered': userB == currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = existingDocument.data()!;

      final userA = data['userA'] as String;
      final userB = data['userB'] as String;

      final currentUserIsA =
          currentUserId == userA;

      await documentReference.update({
        if (currentUserIsA)
          'userADiscovered': true
        else
          'userBDiscovered': true,

        if (currentUserIsA)
          'journeyA': journeyId
        else
          'journeyB': journeyId,
      });
    }

    final updatedDocument =
        await documentReference.get();

    final updatedData =
        updatedDocument.data()!;

    final userA =
        updatedData['userA'] as String;

    final userB =
        updatedData['userB'] as String;

    final currentUserIsA =
        currentUserId == userA;

    final iDiscovered = currentUserIsA
        ? updatedData['userADiscovered'] == true
        : updatedData['userBDiscovered'] == true;

    final otherUserDiscovered = currentUserIsA
        ? updatedData['userBDiscovered'] == true
        : updatedData['userADiscovered'] == true;

    return DiscoverResult(
      discoveryId: discoveryId,
      iDiscovered: iDiscovered,
      otherUserDiscovered: otherUserDiscovered,
      isMutual: iDiscovered && otherUserDiscovered,
    );
  }
}