import 'package:flutter/material.dart';

class MemoryCardScreen extends StatelessWidget {
  final String userName;
  final String otherUserName;
  final String meetingPlace;
  final String meetingPlaceType;
  final String date;
  final List<String> sharedInterests;
  final int crossingCount;
  final double distanceMeters;

  const MemoryCardScreen({
    super.key,
    required this.userName,
    required this.otherUserName,
    required this.meetingPlace,
    required this.meetingPlaceType,
    required this.date,
    required this.sharedInterests,
    required this.crossingCount,
    required this.distanceMeters,
  });

  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        title: const Text(
          'Memory Card',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            children: [
              _buildMemoryCard(),
              const SizedBox(height: 20),
              const Text(
                'A moment created when two journeys crossed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE3ED),
            Color(0xFFFFF8FB),
            Color(0xFFEFE7FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Text(
              'CROSSPATH',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Color(0xFF8E526B),
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'MEMORY',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Your paths crossed.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            // Travellers
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPerson(
                      userName,
                      Icons.person_rounded,
                    ),
                  ),

                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFE28AA8),
                      size: 20,
                    ),
                  ),

                  Expanded(
                    child: _buildPerson(
                      otherUserName,
                      Icons.person_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Meeting place
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDFE9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFD65F87),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WHERE YOUR PATHS MET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Colors.black45,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          meetingPlace,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          meetingPlaceType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Journey information
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    Icons.route_rounded,
                    distanceText,
                    'Distance',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildStat(
                    Icons.sync_rounded,
                    '$crossingCount',
                    'Crossings',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildStat(
                    Icons.calendar_today_rounded,
                    date,
                    'Date',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Shared interests
            if (sharedInterests.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMMON INTERESTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.black45,
                      ),
                    ),

                    const SizedBox(height: 11),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sharedInterests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5EC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7B4A61),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            // Closing message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF9A6077),
                    size: 22,
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Two journeys.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  Text(
                    'One unexpected connection.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerson(
    String name,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF4DCE6),
          ),
          child: Icon(
            icon,
            color: Color(0xFF9A6077),
            size: 27,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF9A6077),
          ),

          const SizedBox(height: 7),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}