import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert username to a consistent format.
  // Aswana, ASWANA, and aswana will all be treated as the same username.
  String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  // Create a Firebase-compatible internal email from the username.
  String _createInternalEmail(String normalizedUsername) {
    return '$normalizedUsername@crosspath.app';
  }

  // Register a new CrossPath user.
  Future<String?> registerUser({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = normalizeUsername(username);

    // Basic username validation
    if (normalizedUsername.isEmpty) {
      return 'Username cannot be empty.';
    }

    if (normalizedUsername.length < 3) {
      return 'Username must be at least 3 characters.';
    }

    // Allow letters, numbers, underscore and dot.
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');

    if (!usernameRegex.hasMatch(normalizedUsername)) {
      return 'Username can contain only letters, numbers, underscores and dots.';
    }

    try {
      // Check whether username already exists.
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .get();

      if (usernameDoc.exists) {
        return 'Username is already taken.';
      }

      // Create Firebase Authentication account.
      final internalEmail = _createInternalEmail(normalizedUsername);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Reserve the username.
      await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .set({
        'uid': uid,
        'username': username.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create the user profile.
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'username': username.trim(),
        'usernameNormalized': normalizedUsername,
        'name': '',
        'photoUrl': null,
        'interests': [],
        'profileComplete': false,
        'discoverable': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This username is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid username.';
        default:
          return e.message ?? 'Registration failed.';
      }
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }


    Future<String?> loginUser({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = normalizeUsername(username);

    if (normalizedUsername.isEmpty) {
      return 'Username cannot be empty.';
    }

    try {
      final internalEmail = _createInternalEmail(normalizedUsername);

      await _auth.signInWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Username not found.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect username or password.';
        case 'invalid-email':
          return 'Invalid username.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return e.message ?? 'Login failed.';
      }
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }
}