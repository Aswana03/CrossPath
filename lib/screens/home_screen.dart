import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'journey_screen.dart';
import 'profile_setup_screen.dart';
import 'profile_screen.dart';
import 'active_match_test_screen.dart';

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

  // ------------------------------------------------------------
  // CHECK PROFILE
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // CURRENT PAGE
  // ------------------------------------------------------------

  Widget _buildCurrentPage() {
    switch (currentIndex) {
      case 1:
        return const JourneyScreen();

      case 2:
        return const ProfileScreen();

      default:
        return _buildHomePage();
    }
  }

  // ============================================================
  // HOME PAGE
  // ============================================================

  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        22,
        25,
        22,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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

              // Profile icon
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

          // ------------------------------------------------------
          // START JOURNEY CARD
          // ------------------------------------------------------

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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: 0.7),
                    borderRadius:
                        BorderRadius.circular(16),
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
                  'Start a journey and discover who might '
                  'cross your path.',
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
                      backgroundColor:
                          const Color(0xFFE85D8E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
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

          // ------------------------------------------------------
          // HOW CROSSPATH WORKS
          // ------------------------------------------------------

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
                  description:
                      'Share your journey path.',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildInfoCard(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Connect',
                  description:
                      'Find meaningful crossings.',
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------
          // YOUR JOURNEYS
          // ------------------------------------------------------

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
                  color:
                      Colors.black.withValues(alpha: 0.04),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // TEMPORARY ACTIVE MATCH TEST BUTTON
          // ------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ActiveMatchTestScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.people_outline_rounded,
                color: Color(0xFFE85D8E),
              ),
              label: const Text(
                'TEST ACTIVE MATCHING',
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
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE PAGE
  // ============================================================

  Widget _buildProfilePage() {
    final user = FirebaseAuth.instance.currentUser;

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

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE85D8E),
            ),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Text(
                'Could not load your profile.\n\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF806B74),
                ),
              ),
            ),
          );
        }

        // --------------------------------------------------------
        // PROFILE NOT FOUND
        // --------------------------------------------------------

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'Profile not found.',
              style: TextStyle(
                color: Color(0xFF806B74),
              ),
            ),
          );
        }

        // --------------------------------------------------------
        // FIRESTORE DATA
        // --------------------------------------------------------

        final data =
            snapshot.data!.data() ?? {};

        final String name =
            (data['name'] ?? '').toString().trim();

        final String username =
            (data['username'] ?? '').toString().trim();

        final String photoUrl =
            (data['photoUrl'] ?? '').toString().trim();

        final interests = <String>[];

        final rawInterests = data['interests'];

        if (rawInterests is List) {
          for (final interest in rawInterests) {
            final value =
                interest.toString().trim();

            if (value.isNotEmpty) {
              interests.add(value);
            }
          }
        }

        // --------------------------------------------------------
        // PROFILE UI
        // --------------------------------------------------------

        return SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            22,
            30,
            22,
            35,
          ),
          child: Column(
            children: [
              const Text(
                'You',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF34262C),
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // PROFILE PHOTO
              // --------------------------------------------------

              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE5EF),
                  border: Border.all(
                    color:
                        const Color(0xFFFFC7DD),
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
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons
                                  .person_outline_rounded,
                              color:
                                  Color(0xFFE85D8E),
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

              const SizedBox(height: 18),

              // --------------------------------------------------
              // NAME
              // --------------------------------------------------

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

              const SizedBox(height: 6),

              // --------------------------------------------------
              // USERNAME
              // --------------------------------------------------

              Text(
                username.isNotEmpty
                    ? '@$username'
                    : 'CrossPath traveller',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9B858E),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your CrossPath profile and interests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF806B74),
                ),
              ),

              const SizedBox(height: 30),

              // --------------------------------------------------
              // PERSONAL DETAILS
              // --------------------------------------------------

              _buildProfileOption(
                icon:
                    Icons.person_outline_rounded,
                title: 'Personal details',
                subtitle: name.isNotEmpty
                    ? name
                    : 'Name not added',
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // INTERESTS
              // --------------------------------------------------

              _buildProfileOption(
                icon: Icons.interests_outlined,
                title: 'Interests',
                subtitle: interests.isNotEmpty
                    ? interests.join(' • ')
                    : 'No interests added',
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // PROFILE PHOTO STATUS
              // --------------------------------------------------

              _buildProfileOption(
                icon:
                    Icons.photo_camera_outlined,
                title: 'Profile photo',
                subtitle: photoUrl.isNotEmpty
                    ? 'Added'
                    : 'Optional',
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // PRIVACY MESSAGE
              // --------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F6),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons
                          .verified_user_outlined,
                      color: Color(0xFFE85D8E),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Your profile information is '
                        'stored securely in Firebase.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF806B74),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

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
            color:
                Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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

  // ============================================================
  // PROFILE OPTION
  // ============================================================

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.035),
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
              borderRadius:
                  BorderRadius.circular(14),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
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
            selectedIcon:
                Icon(Icons.home_rounded),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon:
                Icon(Icons.route_rounded),
            label: 'Journey',
          ),

          NavigationDestination(
            icon:
                Icon(Icons.person_outline_rounded),
            selectedIcon:
                Icon(Icons.person_rounded),
            label: 'You',
          ),
        ],
      ),
    );
  }
}