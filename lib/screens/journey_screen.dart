import 'dart:async';



import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:geocoding/geocoding.dart';

import 'package:firebase_auth/firebase_auth.dart';



import 'destination_screen.dart';



class JourneyScreen extends StatefulWidget {

  const JourneyScreen({super.key});



  @override

  State<JourneyScreen> createState() => _JourneyScreenState();

}



class _JourneyScreenState extends State<JourneyScreen> {

  // ============================================================

  // GPS

  // ============================================================



  StreamSubscription<Position>? positionSubscription;



  Position? currentPosition;



  // ============================================================

  // TIMER

  // ============================================================



  Timer? durationTimer;



  // ============================================================

  // JOURNEY STATE

  // ============================================================



  bool isJourneyActive = false;

  bool isLoadingLocation = false;



  DateTime? journeyStartTime;



  int locationPoints = 0;



  String? currentDestination;



  // ============================================================

  // DESTINATION COORDINATES

  // ============================================================



  double? destinationLatitude;

  double? destinationLongitude;



  double? distanceToDestination;



  // Arrival radius.

  // If user comes within 100 metres of destination,

  // the journey will be automatically completed.

  static const double arrivalRadius = 100.0;



  // ============================================================

  // FIREBASE

  // ============================================================



  final FirebaseFirestore _firestore =

      FirebaseFirestore.instance;



  final FirebaseAuth _auth =

      FirebaseAuth.instance;



  // Geocoding service
  final Geocoding _geocoding = Geocoding();



  String? currentJourneyId;



  // ============================================================

  // DISPOSE

  // ============================================================



  @override

  void dispose() {

    positionSubscription?.cancel();

    durationTimer?.cancel();



    super.dispose();

  }



  // ============================================================

  // LOCATION PERMISSION

  // ============================================================



  Future<bool> checkLocationPermission() async {

    final serviceEnabled =

        await Geolocator.isLocationServiceEnabled();



    if (!serviceEnabled) {

      if (!mounted) return false;



      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(

            'Please turn on Location Services on your phone.',

          ),

        ),

      );



      await Geolocator.openLocationSettings();



      return false;

    }



    LocationPermission permission =

        await Geolocator.checkPermission();



    if (permission == LocationPermission.denied) {

      permission =

          await Geolocator.requestPermission();

    }



    if (permission == LocationPermission.denied) {

      if (!mounted) return false;



      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(

            'Location permission was denied.',

          ),

        ),

      );



      return false;

    }



    if (permission ==

        LocationPermission.deniedForever) {

      if (!mounted) return false;



      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(

            'Location permission is permanently denied. '

            'Please enable it from Settings.',

          ),

        ),

      );



      await Geolocator.openAppSettings();



      return false;

    }



    return true;

  }



  // ============================================================

  // CONVERT DESTINATION NAME TO COORDINATES

  // ============================================================



  Future<bool> getDestinationCoordinates(

    String destination,

  ) async {

    try {

      debugPrint(

        'Searching destination: $destination',

      );



      final locations =

          await _geocoding.locationFromAddress(destination);



      if (locations.isEmpty) {

        return false;

      }



      final location = locations.first;



      destinationLatitude =

          location.latitude;



      destinationLongitude =

          location.longitude;



      debugPrint(

        'Destination latitude: '

        '${location.latitude}',

      );



      debugPrint(

        'Destination longitude: '

        '${location.longitude}',

      );



      return true;

    } catch (e) {

      debugPrint(

        'Destination geocoding failed: $e',

      );



      return false;

    }

  }



  // ============================================================

  // CREATE JOURNEY IN FIRESTORE

  // ============================================================



  Future<void> createJourneyInFirestore(

    Position initialPosition,

  ) async {

    final user = _auth.currentUser;



    if (user == null) {

      throw Exception(

        'User is not logged in.',

      );

    }



    final journeyRef = await _firestore

        .collection('users')

        .doc(user.uid)

        .collection('journeys')

        .add({

      'destination': currentDestination,



      'destinationLatitude':

          destinationLatitude,



      'destinationLongitude':

          destinationLongitude,



      'startTime':

          FieldValue.serverTimestamp(),



      'endTime': null,



      'status': 'active',



      'createdAt':

          FieldValue.serverTimestamp(),

    });



    currentJourneyId =

        journeyRef.id;



    // Save first GPS point.

    await journeyRef

        .collection('points')

        .add({

      'latitude':

          initialPosition.latitude,



      'longitude':

          initialPosition.longitude,



      'accuracy':

          initialPosition.accuracy,



      'timestamp':

          FieldValue.serverTimestamp(),

    });

  }



  // ============================================================

  // SAVE GPS POINT

  // ============================================================



  Future<void> saveGpsPoint(

    Position position,

  ) async {

    final user = _auth.currentUser;



    if (user == null ||

        currentJourneyId == null) {

      return;

    }



    try {

      await _firestore

          .collection('users')

          .doc(user.uid)

          .collection('journeys')

          .doc(currentJourneyId)

          .collection('points')

          .add({

        'latitude':

            position.latitude,



        'longitude':

            position.longitude,



        'accuracy':

            position.accuracy,



        'timestamp':

            FieldValue.serverTimestamp(),

      });

    } catch (e) {

      debugPrint(

        'Error saving GPS point: $e',

      );

    }

  }



  // ============================================================

  // CHECK DISTANCE TO DESTINATION

  // ============================================================



  Future<void> checkDestinationReached(

    Position position,

  ) async {

    if (destinationLatitude == null ||

        destinationLongitude == null) {

      return;

    }



    final distance =

        Geolocator.distanceBetween(

      position.latitude,

      position.longitude,

      destinationLatitude!,

      destinationLongitude!,

    );



    if (mounted) {

      setState(() {

        distanceToDestination =

            distance;

      });

    }



    debugPrint(

      'Distance to destination: '

      '${distance.toStringAsFixed(1)} m',

    );



    // ==========================================================

    // DESTINATION REACHED

    // ==========================================================



    if (distance <= arrivalRadius &&

        isJourneyActive) {

      await destinationReached();

    }

  }



  // ============================================================

  // DESTINATION REACHED

  // ============================================================



  Future<void> destinationReached() async {

    if (!isJourneyActive) {

      return;

    }



    // Stop GPS stream.

    await positionSubscription?.cancel();



    positionSubscription = null;



    // Stop duration timer.

    durationTimer?.cancel();



    durationTimer = null;



    // ----------------------------------------------------------

    // Update Firestore

    // ----------------------------------------------------------



    final user = _auth.currentUser;



    if (user != null &&

        currentJourneyId != null) {

      try {

        await _firestore

            .collection('users')

            .doc(user.uid)

            .collection('journeys')

            .doc(currentJourneyId)

            .update({

          'endTime':

              FieldValue.serverTimestamp(),



          'status':

              'completed',



          'completedReason':

              'destination_reached',

        });

      } catch (e) {

        debugPrint(

          'Error completing journey: $e',

        );

      }

    }



    if (!mounted) {

      return;

    }



    setState(() {

      isJourneyActive = false;

    });



    // ----------------------------------------------------------

    // Show arrival dialog

    // ----------------------------------------------------------



    await showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(

            borderRadius:

                BorderRadius.circular(22),

          ),



          title: const Row(

            children: [

              Text(

                '🎉',

                style: TextStyle(

                  fontSize: 28,

                ),

              ),



              SizedBox(width: 10),



              Expanded(

                child: Text(

                  'Destination reached!',

                  style: TextStyle(

                    fontWeight:

                        FontWeight.w700,

                  ),

                ),

              ),

            ],

          ),



          content: Text(

            'You have reached '

            '$currentDestination.',

          ),



          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text(

                'DONE',

              ),

            ),

          ],

        );

      },

    );

  }



  // ============================================================

  // START JOURNEY

  // ============================================================



  Future<void> startJourney() async {

    // ----------------------------------------------------------

    // Ask for destination

    // ----------------------------------------------------------



    final destination =

        await Navigator.push<String>(

      context,

      MaterialPageRoute(

        builder: (context) =>

            const DestinationScreen(),

      ),

    );



    if (destination == null ||

        destination.trim().isEmpty) {

      return;

    }



    currentDestination =

        destination.trim();



    // ----------------------------------------------------------

    // Loading

    // ----------------------------------------------------------



    if (mounted) {

      setState(() {

        isLoadingLocation = true;



        distanceToDestination = null;



        destinationLatitude = null;



        destinationLongitude = null;

      });

    }



    // ----------------------------------------------------------

    // Convert destination into coordinates

    // ----------------------------------------------------------



    final destinationFound =

        await getDestinationCoordinates(

      currentDestination!,

    );



    if (!destinationFound) {

      if (!mounted) return;



      setState(() {

        isLoadingLocation = false;

      });



      ScaffoldMessenger.of(context)

          .showSnackBar(

        const SnackBar(

          content: Text(

            'Could not find this destination. '

            'Please enter a more specific place.',

          ),

        ),

      );



      return;

    }



    // ----------------------------------------------------------

    // Check permission

    // ----------------------------------------------------------



    final hasPermission =

        await checkLocationPermission();



    if (!hasPermission) {

      if (mounted) {

        setState(() {

          isLoadingLocation = false;

        });

      }



      return;

    }



    // ----------------------------------------------------------

    // Start GPS

    // ----------------------------------------------------------



    try {

      final initialPosition =

          await Geolocator.getCurrentPosition(

        locationSettings:

            const LocationSettings(

          accuracy:

              LocationAccuracy.high,

        ),

      );



      // --------------------------------------------------------

      // Create Firestore journey

      // --------------------------------------------------------



      await createJourneyInFirestore(

        initialPosition,

      );



      if (!mounted) return;



      // --------------------------------------------------------

      // Update UI

      // --------------------------------------------------------



      setState(() {

        currentPosition =

            initialPosition;



        isJourneyActive = true;



        journeyStartTime =

            DateTime.now();



        locationPoints = 1;



        isLoadingLocation = false;

      });



      // --------------------------------------------------------

      // Check if already at destination

      // --------------------------------------------------------



      await checkDestinationReached(

        initialPosition,

      );



      // If destination was already reached,

      // don't start the GPS stream.

      if (!isJourneyActive) {

        return;

      }



      // --------------------------------------------------------

      // START DURATION TIMER

      // --------------------------------------------------------



      durationTimer?.cancel();



      durationTimer =

          Timer.periodic(

        const Duration(seconds: 1),

        (_) {

          if (mounted &&

              isJourneyActive) {

            setState(() {});

          }

        },

      );



      // --------------------------------------------------------

      // START GPS STREAM

      // --------------------------------------------------------



      positionSubscription?.cancel();



      positionSubscription =

          Geolocator.getPositionStream(

        locationSettings:

            const LocationSettings(

          accuracy:

              LocationAccuracy.high,



          // Get another GPS update after

          // approximately 1 metre of movement.

          distanceFilter: 1,

        ),

      ).listen(

        (Position position) async {

          if (!mounted ||

              !isJourneyActive) {

            return;

          }



          // ----------------------------------------------------

          // Update UI

          // ----------------------------------------------------



          setState(() {

            currentPosition =

                position;



            locationPoints++;

          });



          // ----------------------------------------------------

          // Save GPS point

          // ----------------------------------------------------



          await saveGpsPoint(

            position,

          );



          // ----------------------------------------------------

          // Check destination

          // ----------------------------------------------------



          await checkDestinationReached(

            position,

          );

        },

      );



      // --------------------------------------------------------

      // Success message

      // --------------------------------------------------------



      if (!mounted) return;



      ScaffoldMessenger.of(context)

          .showSnackBar(

        SnackBar(

          content: Text(

            'Journey started to '

            '$currentDestination',

          ),

        ),

      );

    } catch (e) {

      if (!mounted) return;



      setState(() {

        isLoadingLocation = false;



        isJourneyActive = false;

      });



      ScaffoldMessenger.of(context)

          .showSnackBar(

        SnackBar(

          content: Text(

            'Could not start journey: $e',

          ),

        ),

      );

    }

  }



  // ============================================================

  // STOP JOURNEY MANUALLY

  // ============================================================



  Future<void> stopJourney() async {

    // Stop GPS.

    await positionSubscription?.cancel();



    positionSubscription = null;



    // Stop timer.

    durationTimer?.cancel();



    durationTimer = null;



    // ----------------------------------------------------------

    // Update Firestore

    // ----------------------------------------------------------



    final user = _auth.currentUser;



    if (user != null &&

        currentJourneyId != null) {

      try {

        await _firestore

            .collection('users')

            .doc(user.uid)

            .collection('journeys')

            .doc(currentJourneyId)

            .update({

          'endTime':

              FieldValue.serverTimestamp(),



          'status':

              'completed',



          'completedReason':

              'manual_stop',

        });

      } catch (e) {

        debugPrint(

          'Error completing journey: $e',

        );

      }

    }



    if (!mounted) return;



    setState(() {

      isJourneyActive = false;

    });



    // ----------------------------------------------------------

    // Message

    // ----------------------------------------------------------



    ScaffoldMessenger.of(context)

        .showSnackBar(

      SnackBar(

        content: Text(

          'Journey completed. '

          '$locationPoints location points recorded.',

        ),

      ),

    );

  }



  // ============================================================

  // JOURNEY DURATION

  // ============================================================



  String getJourneyDuration() {

    if (journeyStartTime == null) {

      return '00:00';

    }



    final duration =

        DateTime.now()

            .difference(journeyStartTime!);



    final hours =

        duration.inHours;



    final minutes =

        duration.inMinutes

            .remainder(60);



    final seconds =

        duration.inSeconds

            .remainder(60);



    if (hours > 0) {

      return '${hours.toString().padLeft(2, '0')}:'

          '${minutes.toString().padLeft(2, '0')}:'

          '${seconds.toString().padLeft(2, '0')}';

    }



    return '${minutes.toString().padLeft(2, '0')}:'

        '${seconds.toString().padLeft(2, '0')}';

  }



  // ============================================================

  // BUILD

  // ============================================================



  @override

  Widget build(BuildContext context) {

    final latitude =

        currentPosition?.latitude;



    final longitude =

        currentPosition?.longitude;



    final accuracy =

        currentPosition?.accuracy;



    return Scaffold(

      backgroundColor:

          const Color(0xFFFFF8FB),



      appBar: AppBar(

        title: const Text(

          'Your Journey',

          style: TextStyle(

            fontWeight:

                FontWeight.w700,

          ),

        ),



        backgroundColor:

            Colors.transparent,



        elevation: 0,

      ),



      body: SafeArea(

        child: SingleChildScrollView(

          padding:

              const EdgeInsets.fromLTRB(

            20,

            10,

            20,

            30,

          ),



          child: Column(

            crossAxisAlignment:

                CrossAxisAlignment.start,



            children: [



              // ==================================================

              // TOP CARD

              // ==================================================



              Container(

                width: double.infinity,



                padding:

                    const EdgeInsets.all(22),



                decoration:

                    BoxDecoration(

                  gradient:

                      const LinearGradient(

                    begin:

                        Alignment.topLeft,

                    end:

                        Alignment.bottomRight,



                    colors: [

                      Color(0xFFFFE4EE),

                      Color(0xFFFFF4F8),

                    ],

                  ),



                  borderRadius:

                      BorderRadius.circular(26),



                  boxShadow: [

                    BoxShadow(

                      color:

                          const Color(

                        0xFFE85D8E,

                      ).withValues(

                        alpha: 0.08,

                      ),



                      blurRadius: 20,



                      offset:

                          const Offset(0, 8),

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

                          width: 52,

                          height: 52,



                          decoration:

                              BoxDecoration(

                            color:

                                const Color(

                              0xFFE85D8E,

                            ),



                            borderRadius:

                                BorderRadius

                                    .circular(

                              17,

                            ),

                          ),



                          child:

                              const Icon(

                            Icons

                                .route_rounded,



                            color:

                                Colors.white,



                            size: 28,

                          ),

                        ),



                        const SizedBox(

                          width: 15,

                        ),



                        Expanded(

                          child: Column(

                            crossAxisAlignment:

                                CrossAxisAlignment

                                    .start,



                            children: [



                              Text(

                                isJourneyActive

                                    ? 'Journey in progress'

                                    : 'Ready for a journey?',



                                style:

                                    const TextStyle(

                                  fontSize: 20,



                                  fontWeight:

                                      FontWeight

                                          .w700,



                                  color:

                                      Color(

                                    0xFF34262C,

                                  ),

                                ),

                              ),



                              const SizedBox(

                                height: 5,

                              ),



                              Text(

                                isJourneyActive

                                    ? 'CrossPath is following your route.'

                                    : 'Start travelling and let CrossPath '

                                      'look for meaningful crossings.',



                                style:

                                    const TextStyle(

                                  fontSize: 13,



                                  height: 1.4,



                                  color:

                                      Color(

                                    0xFF806B74,

                                  ),

                                ),

                              ),

                            ],

                          ),

                        ),

                      ],

                    ),



                    const SizedBox(

                      height: 25,

                    ),



                    // ==================================================

                    // START / STOP BUTTON

                    // ==================================================



                    SizedBox(

                      width: double.infinity,



                      height: 55,



                      child:

                          ElevatedButton(

                        onPressed:

                            isLoadingLocation

                                ? null

                                : isJourneyActive

                                    ? stopJourney

                                    : startJourney,



                        style:

                            ElevatedButton

                                .styleFrom(

                          backgroundColor:

                              const Color(

                            0xFFE85D8E,

                          ),



                          foregroundColor:

                              Colors.white,



                          elevation: 0,



                          shape:

                              RoundedRectangleBorder(

                            borderRadius:

                                BorderRadius

                                    .circular(

                              17,

                            ),

                          ),

                        ),



                        child:

                            isLoadingLocation

                                ? const SizedBox(

                                    width: 23,

                                    height: 23,



                                    child:

                                        CircularProgressIndicator(

                                      strokeWidth:

                                          2.5,



                                      color:

                                          Colors.white,

                                    ),

                                  )

                                : Row(

                                    mainAxisAlignment:

                                        MainAxisAlignment

                                            .center,



                                    children: [



                                      Icon(

                                        isJourneyActive

                                            ? Icons

                                                .stop_rounded

                                            : Icons

                                                .play_arrow_rounded,

                                      ),



                                      const SizedBox(

                                        width: 8,

                                      ),



                                      Text(

                                        isJourneyActive

                                            ? 'STOP JOURNEY'

                                            : 'START JOURNEY',



                                        style:

                                            const TextStyle(

                                          fontWeight:

                                              FontWeight

                                                  .w700,



                                          letterSpacing:

                                              0.8,

                                        ),

                                      ),

                                    ],

                                  ),

                      ),

                    ),

                  ],

                ),

              ),



              const SizedBox(

                height: 22,

              ),



              // ==================================================

              // DESTINATION

              // ==================================================



              if (currentDestination != null) ...[

                const Text(

                  'DESTINATION',



                  style: TextStyle(

                    fontSize: 12,



                    fontWeight:

                        FontWeight.w700,



                    letterSpacing: 1,



                    color:

                        Color(0xFF806B74),

                  ),

                ),



                const SizedBox(

                  height: 10,

                ),



                Container(

                  width: double.infinity,



                  padding:

                      const EdgeInsets.all(

                    18,

                  ),



                  decoration:

                      BoxDecoration(

                    color: Colors.white,



                    borderRadius:

                        BorderRadius.circular(

                      20,

                    ),



                    border: Border.all(

                      color:

                          const Color(

                        0xFFF0DCE4,

                      ),

                    ),

                  ),



                  child: Row(

                    children: [



                      Container(

                        width: 42,

                        height: 42,



                        decoration:

                            BoxDecoration(

                          color:

                              const Color(

                            0xFFFFE3ED,

                          ),



                          borderRadius:

                              BorderRadius

                                  .circular(

                            13,

                          ),

                        ),



                        child: const Icon(

                          Icons

                              .flag_outlined,



                          color:

                              Color(

                            0xFFE85D8E,

                          ),

                        ),

                      ),



                      const SizedBox(

                        width: 13,

                      ),



                      Expanded(

                        child: Column(

                          crossAxisAlignment:

                              CrossAxisAlignment

                                  .start,



                          children: [



                            Text(

                              currentDestination!,



                              style:

                                  const TextStyle(

                                fontSize: 15,



                                fontWeight:

                                    FontWeight

                                        .w600,



                                color:

                                    Color(

                                  0xFF34262C,

                                ),

                              ),

                            ),



                            if (distanceToDestination !=

                                    null &&

                                isJourneyActive) ...[

                              const SizedBox(

                                height: 5,

                              ),



                              Text(

                                distanceToDestination! <

                                        1000

                                    ? '${distanceToDestination!.toStringAsFixed(0)} m away'

                                    : '${(distanceToDestination! / 1000).toStringAsFixed(2)} km away',



                                style:

                                    const TextStyle(

                                  fontSize: 12,



                                  color:

                                      Color(

                                    0xFFE85D8E,

                                  ),



                                  fontWeight:

                                      FontWeight

                                          .w600,

                                ),

                              ),

                            ],

                          ],

                        ),

                      ),

                    ],

                  ),

                ),



                const SizedBox(

                  height: 22,

                ),

              ],



              // ==================================================

              // LIVE LOCATION

              // ==================================================



              const Text(

                'LIVE LOCATION',



                style: TextStyle(

                  fontSize: 12,



                  fontWeight:

                      FontWeight.w700,



                  letterSpacing: 1,



                  color:

                      Color(0xFF806B74),

                ),

              ),



              const SizedBox(

                height: 10,

              ),



              Container(

                width: double.infinity,



                padding:

                    const EdgeInsets.all(

                  20,

                ),



                decoration:

                    BoxDecoration(

                  color: Colors.white,



                  borderRadius:

                      BorderRadius.circular(

                    22,

                  ),



                  border: Border.all(

                    color:

                        const Color(

                      0xFFF0DCE4,

                    ),

                  ),

                ),



                child: Column(

                  children: [



                    _locationRow(

                      icon:

                          Icons

                              .location_on_outlined,



                      title:

                          'Latitude',



                      value:

                          latitude == null

                              ? '--'

                              : latitude

                                  .toStringAsFixed(

                                  6,

                                ),

                    ),



                    const Divider(

                      height: 25,



                      color:

                          Color(0xFFF4E7EC),

                    ),



                    _locationRow(

                      icon:

                          Icons

                              .explore_outlined,



                      title:

                          'Longitude',



                      value:

                          longitude == null

                              ? '--'

                              : longitude

                                  .toStringAsFixed(

                                  6,

                                ),

                    ),



                    const Divider(

                      height: 25,



                      color:

                          Color(0xFFF4E7EC),

                    ),



                    _locationRow(

                      icon:

                          Icons

                              .gps_fixed_rounded,



                      title:

                          'Accuracy',



                      value:

                          accuracy == null

                              ? '--'

                              : '${accuracy.toStringAsFixed(1)} m',

                    ),

                  ],

                ),

              ),



              const SizedBox(

                height: 22,

              ),



              // ==================================================

              // JOURNEY STATS

              // ==================================================



              const Text(

                'JOURNEY STATS',



                style: TextStyle(

                  fontSize: 12,



                  fontWeight:

                      FontWeight.w700,



                  letterSpacing: 1,



                  color:

                      Color(0xFF806B74),

                ),

              ),



              const SizedBox(

                height: 10,

              ),



              Row(

                children: [



                  Expanded(

                    child: _statCard(

                      icon:

                          Icons

                              .timer_outlined,



                      title:

                          'Duration',



                      value:

                          getJourneyDuration(),

                    ),

                  ),



                  const SizedBox(

                    width: 12,

                  ),



                  Expanded(

                    child: _statCard(

                      icon:

                          Icons

                              .my_location_rounded,



                      title:

                          'Points',



                      value:

                          '$locationPoints',

                    ),

                  ),

                ],

              ),



              const SizedBox(

                height: 25,

              ),



              // ==================================================

              // PRIVACY

              // ==================================================



              Container(

                width: double.infinity,



                padding:

                    const EdgeInsets.all(

                  18,

                ),



                decoration:

                    BoxDecoration(

                  color:

                      const Color(

                    0xFFFFF0F5,

                  ),



                  borderRadius:

                      BorderRadius.circular(

                    20,

                  ),

                ),



                child: const Row(

                  crossAxisAlignment:

                      CrossAxisAlignment

                          .start,



                  children: [



                    Icon(

                      Icons

                          .lock_outline_rounded,



                      color:

                          Color(

                        0xFFE85D8E,

                      ),



                      size: 22,

                    ),



                    SizedBox(

                      width: 12,

                    ),



                    Expanded(

                      child: Text(

                        'Your exact location is used only to '

                        'understand your journey and find '

                        'meaningful crossings. It is not shown '

                        'to other users.',



                        style:

                            TextStyle(

                          fontSize: 12.5,



                          height: 1.45,



                          color:

                              Color(

                            0xFF806B74,

                          ),

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

    );

  }



  // ============================================================

  // LOCATION ROW

  // ============================================================



  Widget _locationRow({

    required IconData icon,

    required String title,

    required String value,

  }) {

    return Row(

      children: [



        Container(

          width: 42,

          height: 42,



          decoration:

              BoxDecoration(

            color:

                const Color(

              0xFFFFE3ED,

            ),



            borderRadius:

                BorderRadius.circular(

              13,

            ),

          ),



          child: Icon(

            icon,



            color:

                const Color(

              0xFFE85D8E,

            ),



            size: 21,

          ),

        ),



        const SizedBox(

          width: 13,

        ),



        Expanded(

          child: Column(

            crossAxisAlignment:

                CrossAxisAlignment

                    .start,



            children: [



              Text(

                title,



                style:

                    const TextStyle(

                  fontSize: 12,



                  color:

                      Color(

                    0xFF806B74,

                  ),

                ),

              ),



              const SizedBox(

                height: 3,

              ),



              Text(

                value,



                style:

                    const TextStyle(

                  fontSize: 15,



                  fontWeight:

                      FontWeight.w600,



                  color:

                      Color(

                    0xFF34262C,

                  ),

                ),

              ),

            ],

          ),

        ),

      ],

    );

  }



  // ============================================================

  // STAT CARD

  // ============================================================



  Widget _statCard({

    required IconData icon,

    required String title,

    required String value,

  }) {

    return Container(

      padding:

          const EdgeInsets.all(

        18,

      ),



      decoration:

          BoxDecoration(

        color: Colors.white,



        borderRadius:

            BorderRadius.circular(

          20,

        ),



        border: Border.all(

          color:

              const Color(

            0xFFF0DCE4,

          ),

        ),

      ),



      child: Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,



        children: [



          Icon(

            icon,



            color:

                const Color(

              0xFFE85D8E,

            ),



            size: 23,

          ),



          const SizedBox(

            height: 13,

          ),



          Text(

            title,



            style:

                const TextStyle(

              fontSize: 12,



              color:

                  Color(

                0xFF806B74,

              ),

            ),

          ),



          const SizedBox(

            height: 4,

          ),



          Text(

            value,



            style:

                const TextStyle(

              fontSize: 19,



              fontWeight:

                  FontWeight.w700,



              color:

                  Color(

                0xFF34262C,

              ),

            ),

          ),

        ],

      ),

    );

  }

}