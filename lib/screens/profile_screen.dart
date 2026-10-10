import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _allInterests = [
    'Technology',
    'Travel',
    'Photography',
    'Music',
    'Movies',
    'Food',
    'Sports',
    'Books',
    'Gaming',
    'Nature',
    'Art',
    'Coding',
  ];

  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  String _name = '';
  List<String> _interests = [];
  bool _discoverable = true;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final document =
          await _firestore.collection('users').doc(user.uid).get();

      if (!document.exists) {
        throw Exception('Profile not found.');
      }

      final data = document.data()!;

      if (!mounted) return;

      setState(() {
        _name = data['name'] as String? ?? '';
        _interests = List<String>.from(data['interests'] ?? []);
        _discoverable = data['discoverable'] as bool? ?? true;
        _photoUrl = data['photoUrl'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load profile: $e'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // EDIT NAME
  // ------------------------------------------------------------

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Personal Details'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    try {
      final user = _auth.currentUser;

      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'name': newName,
      });

      if (!mounted) return;

      setState(() {
        _name = newName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name: $e'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // EDIT INTERESTS
  // ------------------------------------------------------------

  Future<void> _editInterests() async {
    final selectedInterests = Set<String>.from(_interests);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Your Interests',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Choose the interests that represent you.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _allInterests.map((interest) {
                              final isSelected =
                                  selectedInterests.contains(interest);

                              return FilterChip(
                                label: Text(interest),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      selectedInterests.add(interest);
                                    } else {
                                      selectedInterests.remove(interest);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedInterests.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select at least one interest.',
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(
                              context,
                              selectedInterests.toList(),
                            );
                          },
                          child: const Text(
                            'SAVE INTERESTS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    try {
      final user = _auth.currentUser;

      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'interests': result,
      });

      if (!mounted) return;

      setState(() {
        _interests = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interests updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update interests: $e'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // DISCOVERABLE
  // ------------------------------------------------------------

  Future<void> _changeDiscoverable(bool value) async {
    try {
      final user = _auth.currentUser;

      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'discoverable': value,
      });

      if (!mounted) return;

      setState(() {
        _discoverable = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'You are now discoverable.'
                : 'You are no longer discoverable.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update setting: $e'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // PROFILE PHOTO
  // ------------------------------------------------------------

  Future<void> _changeProfilePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      final file = File(pickedFile.path);

      final storageReference = _storage
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      await storageReference.putFile(file);

      final downloadUrl = await storageReference.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      if (!mounted) return;

      setState(() {
        _photoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // PROFILE PHOTO WIDGET
  // ------------------------------------------------------------

  Widget _buildProfilePhoto() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFC1D9),
                Color(0xFFFCE4EC),
              ],
            ),
            border: Border.all(
              color: Colors.white,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: _photoUrl != null && _photoUrl!.isNotEmpty
                ? Image.network(
                    _photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.pink,
                      );
                    },
                  )
                : const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.pink,
                  ),
          ),
        ),

        GestureDetector(
          onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE91E63),
              shape: BoxShape.circle,
            ),
            child: _isUploadingPhoto
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt,
                    size: 19,
                    color: Colors.white,
                  ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PROFILE ROW
  // ------------------------------------------------------------

  Widget _buildProfileRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE91E63),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F9),
              Color(0xFFFFFFFF),
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),

            child: Column(
              children: [
                const SizedBox(height: 10),

                // PROFILE PHOTO
                _buildProfilePhoto(),

                const SizedBox(height: 14),

                Text(
                  _name.isEmpty ? 'Your Name' : _name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Tap the items below to edit your profile',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 28),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PERSONAL INFORMATION',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // NAME
                _buildProfileRow(
                  icon: Icons.person_outline,
                  title: 'Personal Details',
                  value: _name.isEmpty ? 'Add your name' : _name,
                  onTap: _editName,
                ),

                const SizedBox(height: 12),

                // INTERESTS
                _buildProfileRow(
                  icon: Icons.interests_outlined,
                  title: 'Interests',
                  value: _interests.isEmpty
                      ? 'Add your interests'
                      : _interests.join(', '),
                  onTap: _editInterests,
                ),

                const SizedBox(height: 12),

                // PROFILE PHOTO
                _buildProfileRow(
                  icon: Icons.photo_camera_outlined,
                  title: 'Profile Photo',
                  value: _photoUrl == null
                      ? 'Add a profile photo'
                      : 'Profile photo added',
                  onTap: _changeProfilePhoto,
                ),

                const SizedBox(height: 28),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DISCOVERY',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // DISCOVERABLE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFFE91E63),
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discoverable',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'Allow other travellers to discover you',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch(
                        value: _discoverable,
                        activeThumbColor: Color(0xFFE91E63),
                        onChanged: _changeDiscoverable,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // PRIVACY NOTE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFE91E63),
                        size: 22,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Your identity remains private until both travellers choose to discover each other.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}