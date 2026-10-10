import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/active_match_service.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  String? _errorMessage;

  List<ActiveMatch> _matches = [];

  Future<void> _findMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _matches = [];
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'No user is currently logged in.',
        );
      }

      // Find the current user's active journey.
      final journeySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journeys')
          .where(
            'status',
            isEqualTo: 'active',
          )
          .limit(1)
          .get();

      if (journeySnapshot.docs.isEmpty) {
        throw Exception(
          'No active journey found. Start a journey first.',
        );
      }

      final myJourneyId =
          journeySnapshot.docs.first.id;

      // Find other users with active journeys.
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
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),

      appBar: AppBar(
        title: const Text('Active Match Test'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF34262C),
        elevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'ACTIVE MATCH TEST',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF34262C),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Find users currently travelling on journeys '
                'that may match your path.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF806B74),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Text(
                  'Logged-in user:\n'
                  '${user?.uid ?? "Not logged in"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF806B74),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _findMatches,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFE85D8E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'FIND ACTIVE MATCHES',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 22),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),

              if (_errorMessage == null &&
                  !_isLoading)
                Text(
                  'Matches found: ${_matches.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34262C),
                  ),
                ),

              const SizedBox(height: 12),

              Expanded(
                child: _matches.isEmpty
                    ? const Center(
                        child: Text(
                          'No active matches yet.',
                          style: TextStyle(
                            color: Color(0xFF9B858E),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _matches.length,
                        itemBuilder:
                            (context, index) {
                          final match =
                              _matches[index];

                          final score =
                              match.score;

                          return Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 14,
                            ),
                            padding:
                                const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 15,
                                  offset:
                                      const Offset(
                                    0,
                                    5,
                                  ),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            const Color(
                                          0xFFFFE5EF,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons
                                            .person_outline_rounded,
                                        color: Color(
                                          0xFFE85D8E,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    const Expanded(
                                      child: Text(
                                        'Potential Match',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: Color(
                                            0xFF34262C,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                Text(
                                  'User ID: ${match.userId}',
                                  style:
                                      const TextStyle(
                                    fontSize: 10,
                                    color: Color(
                                      0xFF9B858E,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 14,
                                ),

                                Container(
                                  width:
                                      double.infinity,
                                  padding:
                                      const EdgeInsets
                                          .all(14),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(
                                      0xFFFFF8FB,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'MATCH SCORE',
                                        style:
                                            TextStyle(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          letterSpacing:
                                              1,
                                          color: Color(
                                            0xFF9B858E,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Text(
                                        '${score.totalScore.toStringAsFixed(2)} / 100',
                                        style:
                                            const TextStyle(
                                          fontSize: 24,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: Color(
                                            0xFFE85D8E,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Text(
                                        score.isMatch
                                            ? 'MATCH ≥ 70'
                                            : 'NOT A MATCH < 70',
                                        style:
                                            TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: score
                                                  .isMatch
                                              ? Colors
                                                  .green
                                              : Colors
                                                  .red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  height: 15,
                                ),

                                _buildScoreRow(
                                  'Route overlap',
                                  score.routeScore,
                                  35,
                                ),

                                _buildScoreRow(
                                  'Destination',
                                  score.destinationScore,
                                  25,
                                ),

                                _buildScoreRow(
                                  'Repeated crossings',
                                  score.crossingScore,
                                  15,
                                ),

                                _buildScoreRow(
                                  'Interests',
                                  score.interestScore,
                                  15,
                                ),

                                _buildScoreRow(
                                  'Direction',
                                  score.directionScore,
                                  5,
                                ),

                                _buildScoreRow(
                                  'Time overlap',
                                  score.timeScore,
                                  5,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(
    String title,
    double score,
    double maximum,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF806B74),
              ),
            ),
          ),

          Text(
            '${score.toStringAsFixed(1)} / ${maximum.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34262C),
            ),
          ),
        ],
      ),
    );
  }
}