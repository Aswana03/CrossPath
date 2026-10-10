import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/journey_data_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String result = 'Testing...';

  @override
  void initState() {
    super.initState();
    testFirebaseData();
  }

  Future<void> testFirebaseData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          result = 'ERROR: No user is logged in.';
        });
        return;
      }

      final uid = user.uid;

      setState(() {
        result = 'Logged in UID:\n$uid\n\nLoading journeys...';
      });

      // We will use the first journey from Firestore.
      // For now, replace this with your actual journey ID.
      const journeyId = '4L5dkBeFgHwdm2ppTwTt';

      final service = JourneyDataService();

      final journey = await service.loadJourneyData(
        userId: uid,
        journeyId: journeyId,
      );

      if (journey == null) {
        setState(() {
          result = 'Journey not found or data could not be loaded.';
        });
        return;
      }

      setState(() {
        result = '''
SUCCESS!

UID:
$uid

GPS points:
${journey.points.length}

Start time:
${journey.startTime}

End time:
${journey.endTime}

Destination latitude:
${journey.destinationLatitude}

Destination longitude:
${journey.destinationLongitude}

Interests:
${journey.interests.join(', ')}

First GPS point:
${journey.points.isNotEmpty ? '${journey.points.first.latitude}, ${journey.points.first.longitude}' : 'No points'}

Last GPS point:
${journey.points.isNotEmpty ? '${journey.points.last.latitude}, ${journey.points.last.longitude}' : 'No points'}
''';
      });
    } catch (e) {
      setState(() {
        result = 'ERROR:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          result,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}