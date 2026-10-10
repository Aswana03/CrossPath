import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/active_match_service.dart';
import 'discover_match_screen.dart';

class ActiveMatchTestScreen extends StatefulWidget {
  const ActiveMatchTestScreen({super.key});

  @override
  State<ActiveMatchTestScreen> createState() =>
      _ActiveMatchTestScreenState();
}

class _ActiveMatchTestScreenState
    extends State<ActiveMatchTestScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isLoading = true;
  String? _errorMessage;

  List<ActiveMatch> _matches = [];

  @override
  void initState() {
    super.initState();
    _findMatches();
  }

  Future<void> _findMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not logged in.');
      }

      // Find the current user's active journey.
      final journeySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('journeys')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (journeySnapshot.docs.isEmpty) {
        throw Exception(
          'No active journey found. Start a journey first.',
        );
      }

      final myJourneyId =
          journeySnapshot.docs.first.id;

      final matches =
          await ActiveMatchService().findActiveMatches(
        myJourneyId: myJourneyId,
      );

      if (!mounted) return;

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _openDiscoverScreen(ActiveMatch match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscoverMatchScreen(
          match: match,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        title: const Text(
          'CrossPath Matches',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _findMatches,
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _findMatches,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.explore_outlined,
              size: 70,
              color: Colors.pinkAccent,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No CrossPath matches yet.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 35,
                ),
                child: Text(
                  'Keep your journey active. '
                  'We will look for people whose '
                  'paths meaningfully cross yours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _findMatches,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Someone crossed your path ✨',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'We found people whose journeys '
            'meaningfully overlap with yours.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 24),

          ..._matches.map(
            (match) => _buildMatchCard(match),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(ActiveMatch match) {
    final score = match.score.totalScore;

    return GestureDetector(
      onTap: () => _openDiscoverScreen(match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pink.shade50,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.pinkAccent,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Someone crossed your path',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Identity hidden until mutual Discover',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.black38,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const Text(
                    'MATCH SCORE / 100',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _scoreRow(
              'Route overlap',
              match.score.routeScore,
              35,
            ),

            _scoreRow(
              'Destination',
              match.score.destinationScore,
              25,
            ),

            _scoreRow(
              'Repeated crossings',
              match.score.crossingScore,
              15,
            ),

            _scoreRow(
              'Shared interests',
              match.score.interestScore,
              15,
            ),

            _scoreRow(
              'Direction',
              match.score.directionScore,
              5,
            ),

            _scoreRow(
              'Time overlap',
              match.score.timeScore,
              5,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _openDiscoverScreen(match),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'VIEW CROSSPATH',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(
    String title,
    double value,
    double maximum,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} / ${maximum.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}