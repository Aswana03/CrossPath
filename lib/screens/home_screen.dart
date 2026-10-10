import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'journey_screen.dart';
import 'profile_setup_screen.dart';
import 'firebase_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  bool isCheckingProfile = true;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isCheckingProfile = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = doc.data();

      setState(() {
        isCheckingProfile = false;
      });

      if (data == null || data['profileComplete'] != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileSetupScreen(),
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCheckingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not check your profile. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8FB),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE85D8E),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      body: SafeArea(
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentPage() {
    switch (currentIndex) {
      case 1:
        return const JourneyScreen();

      case 2:
        return _buildProfilePage();

      default:
        return _buildHomePage();
    }
  }

  // ------------------------------------------------------------
  // HOME
  // ------------------------------------------------------------

  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GOOD TO SEE YOU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0xFF9B858E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your journey awaits.',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34262C),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE85D8E)
                          .withValues(alpha: 0.12),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFE85D8E),
                  size: 25,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Main journey card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE5EF),
                  Color(0xFFFFC7DD),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE85D8E)
                      .withValues(alpha: 0.14),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFFE85D8E),
                    size: 25,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Where are you going?',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF34262C),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Start a journey and discover who might cross your path.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF806B74),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentIndex = 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D8E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'START A JOURNEY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'HOW CROSSPATH WORKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Color(0xFF9B858E),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.route_rounded,
                  title: 'Travel',
                  description: 'Share your journey path.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Connect',
                  description: 'Find meaningful crossings.',
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            'YOUR JOURNEYS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Color(0xFF9B858E),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.explore_outlined,
                  color: Color(0xFFE85D8E),
                  size: 28,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No journeys yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34262C),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Your completed journeys will appear here.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9B858E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // JOURNEY
  // ------------------------------------------------------------

  Widget _buildJourneyPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5EF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.route_rounded,
                color: Color(0xFFE85D8E),
                size: 42,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Start your journey',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Color(0xFF34262C),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Choose where you are heading and let CrossPath discover meaningful connections along the way.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF806B74),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Destination and GPS tracking will be added next.',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85D8E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: const Text(
                  'CHOOSE DESTINATION',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFILE
  // ------------------------------------------------------------

 Widget _buildProfilePage() {
  final user = FirebaseAuth.instance.currentUser;

  // No logged-in user
  if (user == null) {
    return const Center(
      child: Text(
        'You are not logged in.',
        style: TextStyle(
          color: Color(0xFF806B74),
        ),
      ),
    );
  }

  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots(),
    builder: (context, snapshot) {
      // ------------------------------------------------
      // LOADING
      // ------------------------------------------------

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE85D8E),
          ),
        );
      }

      // ------------------------------------------------
      // ERROR
      // ------------------------------------------------

      if (snapshot.hasError) {
        return const Center(
          child: Text(
            'Could not load your profile.',
            style: TextStyle(
              color: Color(0xFF806B74),
            ),
          ),
        );
      }

      // ------------------------------------------------
      // PROFILE DOES NOT EXIST
      // ------------------------------------------------

      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const Center(
          child: Text(
            'Profile not found.',
            style: TextStyle(
              color: Color(0xFF806B74),
            ),
          ),
        );
      }

      // ------------------------------------------------
      // READ FIRESTORE DATA
      // ------------------------------------------------

      final data = snapshot.data!.data() ?? {};

      final String name =
          (data['name'] ?? '').toString().trim();

      final List<dynamic> rawInterests =
          data['interests'] is List
              ? data['interests'] as List<dynamic>
              : [];

      final List<String> interests = rawInterests
          .map((interest) => interest.toString())
          .where((interest) => interest.trim().isNotEmpty)
          .toList();

      final String photoUrl =
          (data['photoUrl'] ?? '').toString().trim();

      // ------------------------------------------------
      // PROFILE PAGE
      // ------------------------------------------------

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          22,
          30,
          22,
          30,
        ),
        child: Column(
          children: [
            // ------------------------------------------------
            // TITLE
            // ------------------------------------------------

            const Text(
              'You',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w700,
                color: Color(0xFF34262C),
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------------
            // PROFILE PHOTO
            // ------------------------------------------------

            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE5EF),
                border: Border.all(
                  color: const Color(0xFFFFC7DD),
                  width: 2,
                ),
              ),
              child: photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFFE85D8E),
                            size: 45,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFFE85D8E),
                      size: 45,
                    ),
            ),
                    const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FirebaseTestScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.cloud_done_outlined,
                color: Color(0xFFE85D8E),
              ),
              label: const Text(
                'TEST FIREBASE DATA',
                style: TextStyle(
                  color: Color(0xFFE85D8E),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFFFC7DD),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

            const SizedBox(height: 15),

            // ------------------------------------------------
            // USER NAME
            // ------------------------------------------------

            Text(
              name.isNotEmpty
                  ? name
                  : 'Your profile',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF34262C),
              ),
            ),

            const SizedBox(height: 7),

            // ------------------------------------------------
            // DESCRIPTION
            // ------------------------------------------------

            Text(
              name.isNotEmpty
                  ? 'Your CrossPath profile and interests.'
                  : 'Add a few details so CrossPath can find better connections.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF806B74),
              ),
            ),

            const SizedBox(height: 30),

            // ------------------------------------------------
            // PERSONAL DETAILS
            // ------------------------------------------------

            _buildProfileOption(
              icon: Icons.person_outline_rounded,
              title: 'Personal details',
              subtitle: name.isNotEmpty
                  ? name
                  : 'Name and nickname',
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------
            // INTERESTS
            // ------------------------------------------------

            _buildProfileOption(
              icon: Icons.interests_outlined,
              title: 'Interests',
              subtitle: interests.isNotEmpty
                  ? interests.join(' • ')
                  : 'Choose what you enjoy',
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------
            // PROFILE PHOTO
            // ------------------------------------------------

            _buildProfileOption(
              icon: Icons.photo_camera_outlined,
              title: 'Profile photo',
              subtitle: photoUrl.isNotEmpty
                  ? 'Added'
                  : 'Optional',
            ),
          ],
        ),
      );
    },
  );
}

  // ------------------------------------------------------------
  // SMALL COMPONENTS
  // ------------------------------------------------------------

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFE85D8E),
            size: 27,
          ),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34262C),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              color: Color(0xFF9B858E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE85D8E),
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF34262C),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9B858E),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: Color(0xFFB9A5AD),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE0EB),
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: 'Journey',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'You',
          ),
        ],
      ),
    );
  }
}