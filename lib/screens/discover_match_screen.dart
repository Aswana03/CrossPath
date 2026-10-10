import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/active_match_service.dart';
import '../services/discover_service.dart';
import '../services/matching_service.dart';

class DiscoverMatchScreen extends StatefulWidget {
  final ActiveMatch match;

  const DiscoverMatchScreen({
    super.key,
    required this.match,
  });

  @override
  State<DiscoverMatchScreen> createState() =>
      _DiscoverMatchScreenState();
}

class _DiscoverMatchScreenState
    extends State<DiscoverMatchScreen> {
  final DiscoverService _discoverService =
      DiscoverService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isDiscovering = false;

  Map<String, dynamic>? _revealedProfile;

  @override
  void initState() {
    super.initState();
  }

  Stream<DiscoverResult?> _discoveryStream() async* {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      yield null;
      return;
    }

    final discoveryId =
        _discoverService.createDiscoveryId(
      currentUser.uid,
      widget.match.userId,
    );

    await for (final snapshot in _firestore
        .collection('discoveries')
        .doc(discoveryId)
        .snapshots()) {
      if (!snapshot.exists) {
        yield null;
        continue;
      }

      final data = snapshot.data();

      if (data == null) {
        yield null;
        continue;
      }

      final userA = data['userA'] as String;
      final userB = data['userB'] as String;

      final currentUserIsA =
          currentUser.uid == userA;

      final iDiscovered = currentUserIsA
          ? data['userADiscovered'] == true
          : data['userBDiscovered'] == true;

      final otherUserDiscovered =
          currentUserIsA
              ? data['userBDiscovered'] == true
              : data['userADiscovered'] == true;

      yield DiscoverResult(
        discoveryId: discoveryId,
        iDiscovered: iDiscovered,
        otherUserDiscovered:
            otherUserDiscovered,
        isMutual:
            iDiscovered && otherUserDiscovered,
      );
    }
  }

  Future<void> _discover() async {
    if (_isDiscovering) return;

    setState(() {
      _isDiscovering = true;
    });

    try {
      await _discoverService.discover(
        otherUserId: widget.match.userId,
        journeyId: widget.match.journeyId,
        score: widget.match.score.totalScore,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not record discovery: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
      }
    }
  }

  Future<void> _loadRevealedProfile() async {
    if (_revealedProfile != null) return;

    try {
      final document = await _firestore
          .collection('users')
          .doc(widget.match.userId)
          .get();

      if (!document.exists) return;

      final data = document.data();

      if (!mounted || data == null) return;

      setState(() {
        _revealedProfile = data;
      });
    } catch (e) {
      debugPrint(
        'Could not load revealed profile: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF7FA),
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DiscoverResult?>(
        stream: _discoveryStream(),
        builder: (context, snapshot) {
          final result = snapshot.data;

          if (result?.isMutual == true) {
            _loadRevealedProfile();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            child: Column(
              children: [
                _buildHeader(),

                const SizedBox(height: 20),

                _buildScoreCard(),

                const SizedBox(height: 18),

                _buildPrivacyCard(),

                const SizedBox(height: 20),

                if (result?.isMutual == true)
                  _buildMutualRevealCard()
                else if (result?.iDiscovered == true)
                  _buildWaitingCard(
                    otherUserDiscovered:
                        result?.otherUserDiscovered ??
                            false,
                  )
                else
                  _buildDiscoverButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        border: Border.all(
          color: Colors.pink.shade100,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.pinkAccent,
            size: 38,
          ),

          SizedBox(height: 12),

          Text(
            'Someone crossed your path',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          Text(
            'You and another traveler shared a meaningful journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = widget.match.score;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'MATCH SCORE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${score.totalScore.round()}%',
            style: const TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),

          const SizedBox(height: 20),

          _scoreRow(
            'Route overlap',
            score.routeScore,
            35,
          ),

          _scoreRow(
            'Destination',
            score.destinationScore,
            25,
          ),

          _scoreRow(
            'Repeated crossings',
            score.crossingScore,
            15,
          ),

          _scoreRow(
            'Shared interests',
            score.interestScore,
            15,
          ),

          _scoreRow(
            'Direction',
            score.directionScore,
            5,
          ),

          _scoreRow(
            'Time overlap',
            score.timeScore,
            5,
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(
    String title,
    double value,
    double maximum,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} / ${maximum.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.pink.shade100,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.pinkAccent,
            size: 30,
          ),

          SizedBox(width: 16),

          Expanded(
            child: Text(
              'Your identity stays private. '
              'Names, photos and personal details '
              'are revealed only when both travelers '
              'choose Discover.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isDiscovering ? null : _discover,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
        child: _isDiscovering
            ? const SizedBox(
                height: 22,
                width: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'DISCOVER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildWaitingCard({
    required bool otherUserDiscovered,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.pink.shade100,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: Colors.pinkAccent,
            size: 45,
          ),

          const SizedBox(height: 16),

          const Text(
            'You discovered them!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            otherUserDiscovered
                ? 'They discovered you too!'
                : 'Waiting for the other traveler to discover you.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          if (!otherUserDiscovered) ...[
            const SizedBox(height: 18),
            const CircularProgressIndicator(
              color: Colors.pinkAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMutualRevealCard() {
    final profile = _revealedProfile;

    final name =
        profile?['name'] as String? ?? '';

    final photoUrl =
        profile?['photoUrl'] as String?;

    final interests =
        (profile?['interests'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite_rounded,
            color: Colors.pinkAccent,
            size: 48,
          ),

          const SizedBox(height: 12),

          const Text(
            'You Crossed Paths! ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'You both chose to discover each other.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 26),

          // PROFILE PHOTO
          if (photoUrl != null &&
              photoUrl.isNotEmpty)
            CircleAvatar(
              radius: 52,
              backgroundImage:
                  NetworkImage(photoUrl),
            )
          else
            CircleAvatar(
              radius: 52,
              backgroundColor:
                  Colors.pink.shade50,
              child: const Icon(
                Icons.person,
                size: 55,
                color: Colors.pinkAccent,
              ),
            ),

          const SizedBox(height: 16),

          // NAME
          Text(
            name.isEmpty
                ? 'Traveler'
                : name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          // INTERESTS
          if (interests.isNotEmpty) ...[
            const Text(
              'INTERESTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.black45,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment:
                  WrapAlignment.center,
              children: interests
                  .map(
                    (interest) =>
                        _interestChip(interest),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Text(
              'Your identities are now visible to each other. '
              'You can continue to create a shared journey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Shared Journey is coming next!',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'CREATE SHARED JOURNEY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        interest,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.pinkAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}