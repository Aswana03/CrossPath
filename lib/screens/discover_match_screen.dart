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

  bool _isLoading = true;
  bool _isDiscovering = false;
  bool _hasDiscovered = false;

  bool _isMutual = false;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryState();
  }

  Future<void> _loadDiscoveryState() async {
    try {
      final result =
          await _discoverService.getDiscovery(
        otherUserId: widget.match.userId,
      );

      if (!mounted) return;

      setState(() {
        if (result != null) {
          _hasDiscovered = result.iDiscovered;
          _isMutual = result.isMutual;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load discovery status: $e',
          ),
        ),
      );
    }
  }

  Future<void> _discover() async {
    if (_isDiscovering || _isMutual) return;

    setState(() {
      _isDiscovering = true;
    });

    try {
      final result =
          await _discoverService.discover(
        otherUserId: widget.match.userId,
        journeyId: widget.match.journeyId,
        score: widget.match.score.totalScore,
      );

      if (!mounted) return;

      setState(() {
        _hasDiscovered = result.iDiscovered;
        _isMutual = result.isMutual;
        _isDiscovering = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDiscovering = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not record discovery: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.match.score;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Discover',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1B24),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE91E63),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),
                child: Column(
                  children: [
                    _buildAnonymousHeader(),
                    const SizedBox(height: 20),
                    _buildScoreCard(score),
                    const SizedBox(height: 16),
                    _buildPrivacyCard(),
                    const SizedBox(height: 24),
                    _buildActionSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnonymousHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE4EF),
            Color(0xFFFFF5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE91E63),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63)
                      .withValues(alpha: 0.20),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Someone crossed your path',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B24),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You and another traveler shared a '
            'meaningful journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6D5963),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(MatchScore score) {
    final total = score.totalScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'MATCH SCORE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xFF8A6875),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${total.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 20),
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
            'Shared interests',
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
  }

  Widget _buildScoreRow(
    String title,
    double value,
    double maximum,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF55434C),
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} / '
            '${maximum.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D1B24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            color: Color(0xFFE91E63),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your identity stays private. '
              'Names, photos and personal details '
              'are revealed only when both travelers '
              'choose Discover.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF6D5963),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_isMutual) {
      return _buildMutualCard();
    }

    if (_hasDiscovered) {
      return _buildWaitingCard();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isDiscovering ? null : _discover,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _isDiscovering
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
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

  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 42,
            color: Color(0xFFE91E63),
          ),
          const SizedBox(height: 12),
          const Text(
            'Waiting for the other traveler',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B24),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You chose to discover this connection. '
            'Your identity will remain private until '
            'they make the same choice.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF6D5963),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE4EF),
            Color(0xFFFFF5F9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 50,
            color: Color(0xFFE91E63),
          ),
          const SizedBox(height: 14),
          const Text(
            'You Crossed Paths!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B24),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You both chose to discover this connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6D5963),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Identity reveal will be added next.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CONTINUE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}