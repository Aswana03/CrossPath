import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'dart:math' as math;



import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';



class SharedJourneyScreen extends StatefulWidget {

  final String otherUserId;

  final String otherUserName;

  final List<String> otherUserInterests;



  const SharedJourneyScreen({

    super.key,

    required this.otherUserId,

    required this.otherUserName,

    required this.otherUserInterests,

  });



  @override

  State<SharedJourneyScreen> createState() =>

      _SharedJourneyScreenState();

}



class _SharedJourneyScreenState extends State<SharedJourneyScreen> {

  bool isLoadingPlaces = true;

  bool isCreating = false;



  String? errorMessage;



  List<MeetingPlace> meetingPlaces = [];

  MeetingPlace? selectedPlace;



  double? commonLatitude;

  double? commonLongitude;



  @override

  void initState() {

    super.initState();

    _findMeetingPlaces();

  }



  // ============================================================

  // DISTANCE CALCULATION

  // ============================================================



  double _distanceInMeters(

    double lat1,

    double lon1,

    double lat2,

    double lon2,

  ) {

    const earthRadius = 6371000.0;



    final dLat = _degreesToRadians(lat2 - lat1);

    final dLon = _degreesToRadians(lon2 - lon1);



    final a =

        math.sin(dLat / 2) * math.sin(dLat / 2) +

        math.cos(_degreesToRadians(lat1)) *

            math.cos(_degreesToRadians(lat2)) *

            math.sin(dLon / 2) *

            math.sin(dLon / 2);



    final c = 2 * math.atan2(

      math.sqrt(a),

      math.sqrt(1 - a),

    );



    return earthRadius * c;

  }



  double _degreesToRadians(double degrees) {

    return degrees * math.pi / 180;

  }



  // ============================================================

  // GET CURRENT USER'S ACTIVE JOURNEY

  // ============================================================



  Future<DocumentSnapshot<Map<String, dynamic>>?>

      _getCurrentUserActiveJourney(String uid) async {

    final snapshot = await FirebaseFirestore.instance

        .collection('users')

        .doc(uid)

        .collection('journeys')

        .where('status', isEqualTo: 'active')

        .limit(1)

        .get();



    if (snapshot.docs.isEmpty) {

      return null;

    }



    return snapshot.docs.first;

  }



  // ============================================================

  // GET OTHER USER'S ACTIVE JOURNEY

  // ============================================================



  Future<DocumentSnapshot<Map<String, dynamic>>?>

      _getOtherUserActiveJourney() async {

    final snapshot = await FirebaseFirestore.instance

        .collection('users')

        .doc(widget.otherUserId)

        .collection('journeys')

        .where('status', isEqualTo: 'active')

        .limit(1)

        .get();



    if (snapshot.docs.isEmpty) {

      return null;

    }



    return snapshot.docs.first;

  }



  // ============================================================

  // GET JOURNEY POINTS

  // ============================================================



  Future<List<RoutePoint>> _getJourneyPoints(

    String uid,

    String journeyId,

  ) async {

    final snapshot = await FirebaseFirestore.instance

        .collection('users')

        .doc(uid)

        .collection('journeys')

        .doc(journeyId)

        .collection('points')

        .get();



    final points = <RoutePoint>[];



    for (final doc in snapshot.docs) {

      final data = doc.data();



      final latitude =

          (data['latitude'] as num?)?.toDouble();



      final longitude =

          (data['longitude'] as num?)?.toDouble();



      if (latitude == null || longitude == null) {

        continue;

      }



      points.add(

        RoutePoint(

          latitude: latitude,

          longitude: longitude,

        ),

      );

    }



    return points;

  }



  // ============================================================

  // FIND COMMON ROUTE AREA

  // ============================================================



  Future<void> _findMeetingPlaces() async {

    final currentUser =

        FirebaseAuth.instance.currentUser;



    if (currentUser == null) {

      setState(() {

        isLoadingPlaces = false;

        errorMessage = 'You must be logged in.';

      });

      return;

    }



    try {

      setState(() {

        isLoadingPlaces = true;

        errorMessage = null;

      });



      final currentJourney =

          await _getCurrentUserActiveJourney(

        currentUser.uid,

      );



      final otherJourney =

          await _getOtherUserActiveJourney();



      if (currentJourney == null ||

          otherJourney == null) {

        throw Exception(

          'Active journey information is not available.',

        );

      }



      final currentPoints = await _getJourneyPoints(

        currentUser.uid,

        currentJourney.id,

      );



      final otherPoints = await _getJourneyPoints(

        widget.otherUserId,

        otherJourney.id,

      );



      if (currentPoints.isEmpty ||

          otherPoints.isEmpty) {

        throw Exception(

          'Not enough route data to find a common meeting area.',

        );

      }



      double smallestDistance =

          double.infinity;



      RoutePoint? bestCurrentPoint;

      RoutePoint? bestOtherPoint;



      for (final pointA in currentPoints) {

        for (final pointB in otherPoints) {

          final distance = _distanceInMeters(

            pointA.latitude,

            pointA.longitude,

            pointB.latitude,

            pointB.longitude,

          );



          if (distance < smallestDistance) {

            smallestDistance = distance;

            bestCurrentPoint = pointA;

            bestOtherPoint = pointB;

          }

        }

      }



      if (bestCurrentPoint == null ||

          bestOtherPoint == null) {

        throw Exception(

          'Could not determine a common route area.',

        );

      }



      final midpointLatitude =

          (bestCurrentPoint.latitude +

                  bestOtherPoint.latitude) /

              2;



      final midpointLongitude =

          (bestCurrentPoint.longitude +

                  bestOtherPoint.longitude) /

              2;



      commonLatitude = midpointLatitude;

      commonLongitude = midpointLongitude;



      final places =

          await _searchOpenStreetMapPlaces(

        midpointLatitude,

        midpointLongitude,

      );



      if (!mounted) return;



      setState(() {

        meetingPlaces = places;

        isLoadingPlaces = false;

      });

    } catch (e) {

      if (!mounted) return;



      setState(() {

        isLoadingPlaces = false;

        errorMessage =

            'Could not find meeting places.\n$e';

      });

    }

  }



  // ============================================================

  // OPENSTREETMAP / OVERPASS SEARCH

  // ============================================================



  Future<List<MeetingPlace>>

      _searchOpenStreetMapPlaces(

    double latitude,

    double longitude,

  ) async {

    const radius = 2000;



    final query = '''

[out:json][timeout:20];

(

  nwr(

    around:$radius,$latitude,$longitude

  )["name"]["amenity"~"cafe|restaurant|library|community_centre|bus_station|marketplace"];



  nwr(

    around:$radius,$latitude,$longitude

  )["name"]["leisure"~"park|garden"];



  nwr(

    around:$radius,$latitude,$longitude

  )["name"]["tourism"~"museum|attraction"];



  nwr(

    around:$radius,$latitude,$longitude

  )["name"]["shop"~"mall|market|supermarket"];

);

out center tags;

''';



    final client = HttpClient();



    try {

      final request = await client.postUrl(

        Uri.parse(

          'https\://overpass-api.de/api/interpreter',

        ),

      );



      request.headers.contentType = ContentType(

        'application',

        'x-www-form-urlencoded',

        charset: 'utf-8',

      );



      request.headers.set(

        HttpHeaders.userAgentHeader,

        'CrossPath/1.0 (Flutter app)',

      );



      request.write(

        'data=${Uri.encodeQueryComponent(query)}',

      );



      final response = await request.close();



      if (response.statusCode != 200) {

        throw Exception(

          'Map service returned ${response.statusCode}.',

        );

      }



      final responseBody =

          await response.transform(

        utf8.decoder,

      ).join();



      final jsonData = jsonDecode(responseBody);



      final elements = jsonData['elements'];



      if (elements is! List) {

        return [];

      }



      final places = <MeetingPlace>[];



      for (final element in elements) {

        if (element is! Map<String, dynamic>) {

          continue;

        }



        final tags = element['tags'];



        if (tags is! Map<String, dynamic>) {

          continue;

        }



        final name = tags['name']?.toString();



        if (name == null || name.trim().isEmpty) {

          continue;

        }



        double? placeLatitude;

        double? placeLongitude;



        if (element['lat'] is num &&

            element['lon'] is num) {

          placeLatitude =

              (element['lat'] as num).toDouble();



          placeLongitude =

              (element['lon'] as num).toDouble();

        } else {

          final center = element['center'];



          if (center is Map<String, dynamic>) {

            if (center['lat'] is num &&

                center['lon'] is num) {

              placeLatitude =

                  (center['lat'] as num).toDouble();



              placeLongitude =

                  (center['lon'] as num).toDouble();

            }

          }

        }



        if (placeLatitude == null ||

            placeLongitude == null) {

          continue;

        }



        final type = _getPlaceType(tags);



        final distance = _distanceInMeters(

          latitude,

          longitude,

          placeLatitude,

          placeLongitude,

        );



        places.add(

          MeetingPlace(

            name: name.trim(),

            type: type,

            latitude: placeLatitude,

            longitude: placeLongitude,

            distanceMeters: distance,

          ),

        );

      }



      final uniquePlaces =

          <String, MeetingPlace>{};



      for (final place in places) {

        final key =

            '${place.name.toLowerCase()}_${place.latitude.toStringAsFixed(5)}_${place.longitude.toStringAsFixed(5)}';



        uniquePlaces[key] = place;

      }



      final result =

          uniquePlaces.values.toList();



      result.sort(

        (a, b) =>

            a.distanceMeters.compareTo(

          b.distanceMeters,

        ),

      );



      return result.take(5).toList();

    } finally {

      client.close(force: true);

    }

  }



  // ============================================================

  // PLACE TYPE

  // ============================================================



  String _getPlaceType(

    Map<String, dynamic> tags,

  ) {

    final amenity =

        tags['amenity']?.toString();



    final leisure =

        tags['leisure']?.toString();



    final tourism =

        tags['tourism']?.toString();



    final shop =

        tags['shop']?.toString();



    if (amenity == 'cafe') {

      return 'Cafe';

    }



    if (amenity == 'restaurant') {

      return 'Restaurant';

    }



    if (amenity == 'library') {

      return 'Library';

    }



    if (amenity == 'community_centre') {

      return 'Community Centre';

    }



    if (amenity == 'bus_station') {

      return 'Bus Station';

    }



    if (amenity == 'marketplace') {

      return 'Market';

    }



    if (leisure == 'park') {

      return 'Park';

    }



    if (leisure == 'garden') {

      return 'Garden';

    }



    if (tourism == 'museum') {

      return 'Museum';

    }



    if (tourism == 'attraction') {

      return 'Public Attraction';

    }



    if (shop == 'mall') {

      return 'Mall';

    }



    if (shop == 'market') {

      return 'Market';

    }



    if (shop == 'supermarket') {

      return 'Supermarket';

    }



    return 'Public Place';

  }



  // ============================================================

  // CREATE SHARED JOURNEY

  // ============================================================



  Future<void> _createSharedJourney() async {

    final currentUser =

        FirebaseAuth.instance.currentUser;



    if (currentUser == null) {

      return;

    }



    if (selectedPlace == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(

            'Please select a meeting place first.',

          ),

        ),

      );

      return;

    }



    setState(() {

      isCreating = true;

    });



    try {

      final userIds = [

        currentUser.uid,

        widget.otherUserId,

      ]..sort();



      final sharedJourneyId =

          '${userIds[0]}_${userIds[1]}';



      await FirebaseFirestore.instance

          .collection('sharedJourneys')

          .doc(sharedJourneyId)

          .set(

        {

          'userA': userIds[0],

          'userB': userIds[1],

          'status': 'active',



          'meetingPlaceName':

              selectedPlace!.name,



          'meetingPlaceType':

              selectedPlace!.type,



          'meetingPlaceLatitude':

              selectedPlace!.latitude,



          'meetingPlaceLongitude':

              selectedPlace!.longitude,



          'commonRouteLatitude':

              commonLatitude,



          'commonRouteLongitude':

              commonLongitude,



          'meetingPlaceSelectedAt':

              FieldValue.serverTimestamp(),



          'createdAt':

              FieldValue.serverTimestamp(),

        },

        SetOptions(merge: true),

      );



      if (!mounted) return;



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            'Shared Journey created with ${selectedPlace!.name}',

          ),

        ),

      );



      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) => MeetupWaitingScreen(

            otherUserId: widget.otherUserId,
            otherUserName:

                widget.otherUserName,

            meetingPlace:

                selectedPlace!.name,

          ),

        ),

      );

    } catch (e) {

      if (!mounted) return;



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            'Failed to create Shared Journey: $e',

          ),

        ),

      );

    } finally {

      if (mounted) {

        setState(() {

          isCreating = false;

        });

      }

    }

  }



  // ============================================================

  // FORMAT DISTANCE

  // ============================================================



  String _formatDistance(

    double meters,

  ) {

    if (meters < 1000) {

      return '${meters.round()} m away';

    }



    return '${(meters / 1000).toStringAsFixed(1)} km away';

  }



  // ============================================================

  // MEETING PLACE CARD

  // ============================================================



  Widget _buildMeetingPlaceCard(

    MeetingPlace place,

  ) {

    final isSelected =

        selectedPlace?.name == place.name &&

        selectedPlace?.latitude ==

            place.latitude &&

        selectedPlace?.longitude ==

            place.longitude;



    return GestureDetector(

      onTap: () {

        setState(() {

          selectedPlace = place;

        });

      },

      child: AnimatedContainer(

        duration:

            const Duration(milliseconds: 200),

        margin:

            const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius:

              BorderRadius.circular(20),

          border: Border.all(

            color: isSelected

                ? const Color(0xFFE91E63)

                : const Color(0xFFF3E6EB),

            width: isSelected ? 2 : 1,

          ),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withValues(

                alpha: 0.035,

              ),

              blurRadius: 12,

              offset:

                  const Offset(0, 4),

            ),

          ],

        ),

        child: Row(

          children: [

            Container(

              width: 52,

              height: 52,

              decoration: BoxDecoration(

                color:

                    const Color(0xFFFFEEF4),

                borderRadius:

                    BorderRadius.circular(16),

              ),

              child: Icon(

                _getPlaceIcon(

                  place.type,

                ),

                color:

                    const Color(0xFFE91E63),

                size: 27,

              ),

            ),



            const SizedBox(width: 14),



            Expanded(

              child: Column(

                crossAxisAlignment:

                    CrossAxisAlignment.start,

                children: [

                  Text(

                    place.name,

                    maxLines: 2,

                    overflow:

                        TextOverflow.ellipsis,

                    style: const TextStyle(

                      fontSize: 16,

                      fontWeight:

                          FontWeight.w700,

                      color:

                          Color(0xFF34262C),

                    ),

                  ),



                  const SizedBox(height: 5),



                  Text(

                    place.type,

                    style: const TextStyle(

                      fontSize: 13,

                      color:

                          Color(0xFFE91E63),

                      fontWeight:

                          FontWeight.w600,

                    ),

                  ),



                  const SizedBox(height: 4),



                  Text(

                    _formatDistance(

                      place.distanceMeters,

                    ),

                    style: const TextStyle(

                      fontSize: 12,

                      color:

                          Color(0xFF806B74),

                    ),

                  ),

                ],

              ),

            ),



            const SizedBox(width: 10),



            Container(

              width: 28,

              height: 28,

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                color: isSelected

                    ? const Color(

                        0xFFE91E63,

                      )

                    : Colors.transparent,

                border: Border.all(

                  color: isSelected

                      ? const Color(

                          0xFFE91E63,

                        )

                      : const Color(

                          0xFFD6C6CD,

                        ),

                  width: 1.5,

                ),

              ),

              child: isSelected

                  ? const Icon(

                      Icons.check,

                      color: Colors.white,

                      size: 18,

                    )

                  : null,

            ),

          ],

        ),

      ),

    );

  }



  // ============================================================

  // ICON

  // ============================================================



  IconData _getPlaceIcon(

    String type,

  ) {

    switch (type) {

      case 'Cafe':

        return Icons.local_cafe_outlined;



      case 'Restaurant':

        return Icons.restaurant_outlined;



      case 'Library':

        return Icons.local_library_outlined;



      case 'Park':

        return Icons.park_outlined;



      case 'Garden':

        return Icons.local_florist_outlined;



      case 'Museum':

        return Icons.museum_outlined;



      case 'Mall':

        return Icons.shopping_bag_outlined;



      case 'Bus Station':

        return Icons.directions_bus_outlined;



      case 'Market':

        return Icons.storefront_outlined;



      case 'Community Centre':

        return Icons.groups_outlined;



      default:

        return Icons.place_outlined;

    }

  }



  // ============================================================

  // BUILD SHARED JOURNEY

  // ============================================================



  @override

  Widget build(

    BuildContext context,

  ) {

    return Scaffold(

      backgroundColor:

          const Color(0xFFFFF7FA),



      appBar: AppBar(

        backgroundColor:

            Colors.transparent,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(

            Icons.arrow_back,

            color:

                Color(0xFF34262C),

          ),

          onPressed: () {

            Navigator.pop(context);

          },

        ),

        title: const Text(

          'Shared Journey',

          style: TextStyle(

            color:

                Color(0xFF34262C),

            fontWeight:

                FontWeight.w700,

          ),

        ),

      ),



      body: SafeArea(

        child: SingleChildScrollView(

          padding:

              const EdgeInsets.all(20),

          child: Column(

            children: [

              const SizedBox(height: 15),



              Container(

                width: 90,

                height: 90,

                decoration:

                    const BoxDecoration(

                  color:

                      Color(0xFFFFDCE9),

                  shape:

                      BoxShape.circle,

                ),

                child: const Icon(

                  Icons.people_alt_outlined,

                  color:

                      Color(0xFFE91E63),

                  size: 45,

                ),

              ),



              const SizedBox(height: 20),



              const Text(

                'Your paths crossed!',

                textAlign:

                    TextAlign.center,

                style: TextStyle(

                  fontSize: 26,

                  fontWeight:

                      FontWeight.w800,

                  color:

                      Color(0xFF34262C),

                ),

              ),



              const SizedBox(height: 8),



              const Text(

                'You both discovered the same connection.',

                textAlign:

                    TextAlign.center,

                style: TextStyle(

                  fontSize: 15,

                  color:

                      Color(0xFF806B74),

                ),

              ),



              const SizedBox(height: 30),



              // ------------------------------------------------

              // OTHER TRAVELLER

              // ------------------------------------------------



              Container(

                width: double.infinity,

                padding:

                    const EdgeInsets.all(20),

                decoration:

                    BoxDecoration(

                  color: Colors.white,

                  borderRadius:

                      BorderRadius.circular(24),

                  boxShadow: [

                    BoxShadow(

                      color:

                          Colors.black.withValues(

                        alpha: 0.04,

                      ),

                      blurRadius: 18,

                      offset:

                          const Offset(0, 6),

                    ),

                  ],

                ),

                child: Column(

                  children: [

                    Container(

                      width: 75,

                      height: 75,

                      decoration:

                          const BoxDecoration(

                        color:

                            Color(0xFFFFDCE9),

                        shape:

                            BoxShape.circle,

                      ),

                      child: const Icon(

                        Icons.person,

                        color:

                            Color(0xFFE91E63),

                        size: 40,

                      ),

                    ),



                    const SizedBox(

                      height: 14,

                    ),



                    Text(

                      widget.otherUserName,

                      style:

                          const TextStyle(

                        fontSize: 22,

                        fontWeight:

                            FontWeight.w700,

                        color:

                            Color(0xFF34262C),

                      ),

                    ),



                    const SizedBox(

                      height: 14,

                    ),



                    if (widget

                        .otherUserInterests

                        .isNotEmpty)

                      Wrap(

                        spacing: 8,

                        runSpacing: 8,

                        alignment:

                            WrapAlignment

                                .center,

                        children: widget

                            .otherUserInterests

                            .map(

                          (interest) =>

                              Container(

                            padding:

                                const EdgeInsets

                                    .symmetric(

                              horizontal: 12,

                              vertical: 7,

                            ),

                            decoration:

                                BoxDecoration(

                              color:

                                  const Color(

                                0xFFFFEEF4,

                              ),

                              borderRadius:

                                  BorderRadius

                                      .circular(

                                20,

                              ),

                            ),

                            child: Text(

                              interest,

                              style:

                                  const TextStyle(

                                fontSize: 12,

                                color:

                                    Color(

                                  0xFFE91E63,

                                ),

                                fontWeight:

                                    FontWeight

                                        .w600,

                              ),

                            ),

                          ),

                        )

                            .toList(),

                      ),

                  ],

                ),

              ),



              const SizedBox(height: 20),



              // ------------------------------------------------

              // COMMON AREA

              // ------------------------------------------------



              Container(

                width: double.infinity,

                padding:

                    const EdgeInsets.all(20),

                decoration:

                    BoxDecoration(

                  color:

                      const Color(0xFFFFEEF4),

                  borderRadius:

                      BorderRadius.circular(22),

                ),

                child: Column(

                  children: [

                    const Icon(

                      Icons.location_on_outlined,

                      color:

                          Color(0xFFE91E63),

                      size: 32,

                    ),



                    const SizedBox(

                      height: 12,

                    ),



                    const Text(

                      'Find a common meeting place',

                      textAlign:

                          TextAlign.center,

                      style: TextStyle(

                        fontSize: 18,

                        fontWeight:

                            FontWeight.w700,

                        color:

                            Color(0xFF34262C),

                      ),

                    ),



                    const SizedBox(

                      height: 8,

                    ),



                    const Text(

                      'We look near the area where your two journeys came closest and suggest public places you can choose together.',

                      textAlign:

                          TextAlign.center,

                      style: TextStyle(

                        fontSize: 14,

                        height: 1.4,

                        color:

                            Color(0xFF806B74),

                      ),

                    ),

                  ],

                ),

              ),



              const SizedBox(height: 20),



              // ------------------------------------------------

              // LOADING

              // ------------------------------------------------



              if (isLoadingPlaces)

                Container(

                  width: double.infinity,

                  padding:

                      const EdgeInsets.all(28),

                  decoration:

                      BoxDecoration(

                    color: Colors.white,

                    borderRadius:

                        BorderRadius.circular(20),

                  ),

                  child: const Column(

                    children: [

                      CircularProgressIndicator(

                        color:

                            Color(0xFFE91E63),

                      ),

                      SizedBox(height: 15),

                      Text(

                        'Finding places near your common route...',

                        textAlign:

                            TextAlign.center,

                        style: TextStyle(

                          color:

                              Color(0xFF806B74),

                        ),

                      ),

                    ],

                  ),

                ),



              // ------------------------------------------------

              // ERROR

              // ------------------------------------------------



              if (!isLoadingPlaces &&

                  errorMessage != null)

                Container(

                  width: double.infinity,

                  padding:

                      const EdgeInsets.all(20),

                  decoration:

                      BoxDecoration(

                    color: Colors.white,

                    borderRadius:

                        BorderRadius.circular(20),

                  ),

                  child: Column(

                    children: [

                      const Icon(

                        Icons.location_off_outlined,

                        color:

                            Color(0xFFE91E63),

                        size: 38,

                      ),



                      const SizedBox(

                        height: 12,

                      ),



                      Text(

                        errorMessage!,

                        textAlign:

                            TextAlign.center,

                        style:

                            const TextStyle(

                          fontSize: 14,

                          height: 1.4,

                          color:

                              Color(0xFF806B74),

                        ),

                      ),



                      const SizedBox(

                        height: 15,

                      ),



                      OutlinedButton(

                        onPressed:

                            _findMeetingPlaces,

                        style:

                            OutlinedButton

                                .styleFrom(

                          foregroundColor:

                              const Color(

                            0xFFE91E63,

                          ),

                          side:

                              const BorderSide(

                            color:

                                Color(

                              0xFFE91E63,

                            ),

                          ),

                        ),

                        child:

                            const Text(

                          'TRY AGAIN',

                        ),

                      ),

                    ],

                  ),

                ),



              // ------------------------------------------------

              // SUGGESTIONS

              // ------------------------------------------------



              if (!isLoadingPlaces &&

                  errorMessage == null &&

                  meetingPlaces.isNotEmpty)

                Column(

                  crossAxisAlignment:

                      CrossAxisAlignment

                          .start,

                  children: [

                    const Text(

                      'Suggested places',

                      style: TextStyle(

                        fontSize: 18,

                        fontWeight:

                            FontWeight.w700,

                        color:

                            Color(0xFF34262C),

                      ),

                    ),



                    const SizedBox(

                      height: 5,

                    ),



                    const Text(

                      'Choose a place that works for both of you.',

                      style: TextStyle(

                        fontSize: 13,

                        color:

                            Color(0xFF806B74),

                      ),

                    ),



                    const SizedBox(

                      height: 14,

                    ),



                    ...meetingPlaces.map(

                      _buildMeetingPlaceCard,

                    ),

                  ],

                ),



              // ------------------------------------------------

              // NO RESULTS

              // ------------------------------------------------



              if (!isLoadingPlaces &&

                  errorMessage == null &&

                  meetingPlaces.isEmpty)

                Container(

                  width: double.infinity,

                  padding:

                      const EdgeInsets.all(22),

                  decoration:

                      BoxDecoration(

                    color: Colors.white,

                    borderRadius:

                        BorderRadius.circular(20),

                  ),

                  child: const Column(

                    children: [

                      Icon(

                        Icons.search_off_outlined,

                        color:

                            Color(0xFFE91E63),

                        size: 38,

                      ),

                      SizedBox(height: 12),

                      Text(

                        'No nearby public places were found.',

                        textAlign:

                            TextAlign.center,

                        style:

                            TextStyle(

                          fontWeight:

                              FontWeight.w600,

                          color:

                              Color(0xFF34262C),

                        ),

                      ),

                      SizedBox(height: 6),

                      Text(

                        'Try again when more route information is available.',

                        textAlign:

                            TextAlign.center,

                        style:

                            TextStyle(

                          fontSize: 13,

                          color:

                              Color(0xFF806B74),

                        ),

                      ),

                    ],

                  ),

                ),



              const SizedBox(height: 25),



              // ------------------------------------------------

              // CREATE BUTTON

              // ------------------------------------------------



              SizedBox(

                width: double.infinity,

                height: 56,

                child: ElevatedButton(

                  onPressed:

                      isCreating ||

                              selectedPlace ==

                                  null

                          ? null

                          : _createSharedJourney,

                  style:

                      ElevatedButton.styleFrom(

                    backgroundColor:

                        const Color(

                      0xFFE91E63,

                    ),

                    disabledBackgroundColor:

                        const Color(

                      0xFFE8C9D5,

                    ),

                    foregroundColor:

                        Colors.white,

                    elevation: 0,

                    shape:

                        RoundedRectangleBorder(

                      borderRadius:

                          BorderRadius.circular(

                        18,

                      ),

                    ),

                  ),

                  child: isCreating

                      ? const SizedBox(

                          width: 24,

                          height: 24,

                          child:

                              CircularProgressIndicator(

                            strokeWidth: 2.5,

                            color:

                                Colors.white,

                          ),

                        )

                      : Text(

                          selectedPlace ==

                                  null

                              ? 'SELECT A MEETING PLACE'

                              : 'CREATE SHARED JOURNEY',

                          style:

                              const TextStyle(

                            fontSize: 15,

                            fontWeight:

                                FontWeight.w700,

                            letterSpacing:

                                0.5,

                          ),

                        ),

                ),

              ),



              const SizedBox(height: 15),



              const Text(

                'Meeting location is based on the common area of your recorded routes.',

                textAlign:

                    TextAlign.center,

                style: TextStyle(

                  fontSize: 12,

                  color:

                      Color(0xFF9B858E),

                ),

              ),



              const SizedBox(height: 15),

            ],

          ),

        ),

      ),

    );

  }

}



// ================================================================

// ROUTE POINT

// ================================================================



class RoutePoint {

  final double latitude;

  final double longitude;



  RoutePoint({

    required this.latitude,

    required this.longitude,

  });

}



// ================================================================

// MEETING PLACE

// ================================================================



class MeetingPlace {

  final String name;

  final String type;

  final double latitude;

  final double longitude;

  final double distanceMeters;



  MeetingPlace({

    required this.name,

    required this.type,

    required this.latitude,

    required this.longitude,

    required this.distanceMeters,

  });

}



// ================================================================

// MEETUP SUCCESS SCREEN

// ================================================================




class MeetupWaitingScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String meetingPlace;

  const MeetupWaitingScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.meetingPlace,
  });

  @override
  State<MeetupWaitingScreen> createState() =>
      _MeetupWaitingScreenState();
}

class _MeetupWaitingScreenState extends State<MeetupWaitingScreen> {
  static const double meetupRadiusMeters = 100.0;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sharedJourneySubscription;

  String? _sharedJourneyId;
  Position? _myPosition;
  double? _distanceToOther;

  bool _isStarting = true;
  bool _isSuccessful = false;
  bool _isWaitingForOther = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startMeetupTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _sharedJourneySubscription?.cancel();
    super.dispose();
  }

  double _distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(
      math.sqrt(a),
      math.sqrt(1 - a),
    );

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  Future<void> _startMeetupTracking() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (!mounted) return;

      setState(() {
        _isStarting = false;
        _errorMessage = 'You must be logged in.';
      });
      return;
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are turned off. Please enable GPS.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Enable location permission for CrossPath in Android Settings.',
        );
      }

      final userIds = [
        currentUser.uid,
        widget.otherUserId,
      ]..sort();

      _sharedJourneyId =
          '${userIds[0]}_${userIds[1]}';

      _listenToOtherUserLocation();

      final initialPosition =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _publishMyLocation(initialPosition);

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          _publishMyLocation(position);
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _errorMessage =
                'Unable to keep updating your location.\n$error';
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isStarting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isStarting = false;
        _errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  void _listenToOtherUserLocation() {
    final sharedJourneyId = _sharedJourneyId;

    if (sharedJourneyId == null) return;

    _sharedJourneySubscription = FirebaseFirestore.instance
        .collection('sharedJourneys')
        .doc(sharedJourneyId)
        .snapshots()
        .listen(
      (snapshot) {
        final data = snapshot.data();

        if (data == null) return;

        final currentUser =
            FirebaseAuth.instance.currentUser;

        if (currentUser == null) return;

        final userA = data['userA']?.toString();
        final userB = data['userB']?.toString();

        if (userA == null || userB == null) return;

        final isUserA = currentUser.uid == userA;

        final rawOtherLocation = isUserA
            ? data['currentLocationB']
            : data['currentLocationA'];

        if (rawOtherLocation is! Map) {
          if (!mounted) return;

          setState(() {
            _isWaitingForOther = true;
            _distanceToOther = null;
          });

          return;
        }

        final otherLatitude =
            (rawOtherLocation['latitude'] as num?)?.toDouble();

        final otherLongitude =
            (rawOtherLocation['longitude'] as num?)?.toDouble();

        if (otherLatitude == null ||
            otherLongitude == null ||
            _myPosition == null) {
          return;
        }

        final distance = _distanceInMeters(
          _myPosition!.latitude,
          _myPosition!.longitude,
          otherLatitude,
          otherLongitude,
        );

        if (!mounted) return;

        setState(() {
          _distanceToOther = distance;
          _isWaitingForOther = false;
        });

        if (distance <= meetupRadiusMeters &&
            !_isSuccessful) {
          _markMeetupSuccessful();
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _errorMessage =
              'Could not receive the other traveller location.\n$error';
        });
      },
    );
  }

  Future<void> _publishMyLocation(
    Position position,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final sharedJourneyId = _sharedJourneyId;

    if (currentUser == null ||
        sharedJourneyId == null ||
        _isSuccessful) {
      return;
    }

    _myPosition = position;

    final sharedJourneyRef = FirebaseFirestore.instance
        .collection('sharedJourneys')
        .doc(sharedJourneyId);

    try {
      final snapshot = await sharedJourneyRef.get();
      final data = snapshot.data();

      if (data == null) return;

      final userA = data['userA']?.toString();
      final userB = data['userB']?.toString();

      if (userA == null || userB == null) return;

      final fieldName = currentUser.uid == userA
          ? 'currentLocationA'
          : 'currentLocationB';

      await sharedJourneyRef.update({
        fieldName: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'updatedAt': Timestamp.now(),
        },
      });

      if (!mounted) return;

      setState(() {
        _myPosition = position;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Could not publish your location.\n$e';
      });
    }
  }

  Future<void> _markMeetupSuccessful() async {
    if (_isSuccessful) return;

    _isSuccessful = true;

    await _positionSubscription?.cancel();
    await _sharedJourneySubscription?.cancel();

    final sharedJourneyId = _sharedJourneyId;

    if (sharedJourneyId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('sharedJourneys')
            .doc(sharedJourneyId)
            .update({
          'meetupStatus': 'successful',
          'meetupSuccessfulAt':
              FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {});

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MeetupSuccessScreen(
          otherUserName: widget.otherUserName,
          meetingPlace: widget.meetingPlace,
        ),
      ),
    );
  }

  String _distanceText() {
    if (_distanceToOther == null) {
      return 'Waiting for the other traveller...';
    }

    final distance = _distanceToOther!;

    if (distance < 1000) {
      return '${distance.round()} m apart';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km apart';
  }

  @override
  Widget build(BuildContext context) {
    final withinRadius =
        _distanceToOther != null &&
        _distanceToOther! <= meetupRadiusMeters;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF34262C),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meetup Check',
          style: TextStyle(
            color: Color(0xFF34262C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDCE9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  withinRadius
                      ? Icons.check_circle_outline
                      : Icons.location_searching,
                  color: const Color(0xFFE91E63),
                  size: 65,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                _isSuccessful
                    ? 'Meetup Successful!'
                    : 'Waiting for meetup...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF34262C),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Meeting place: ${widget.meetingPlace}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF806B74),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: Color(0xFFE91E63),
                      size: 38,
                    ),

                    const SizedBox(height: 14),

                    Text(
                      _distanceText(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE91E63),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Meetup succeeds when both travellers are within 100 metres of each other.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF806B74),
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (_isStarting)
                      const CircularProgressIndicator(
                        color: Color(0xFFE91E63),
                      )
                    else if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF806B74),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            color: Color(0xFFE91E63),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isWaitingForOther
                                ? 'Waiting for ${widget.otherUserName}...'
                                : 'Live GPS tracking active',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF806B74),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (!_isSuccessful)
                const Text(
                  'Keep this screen open while travelling to the selected meeting place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF9B858E),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeetupSuccessScreen extends StatelessWidget {

  final String otherUserName;

  final String meetingPlace;



  const MeetupSuccessScreen({

    super.key,

    required this.otherUserName,

    required this.meetingPlace,

  });



  @override

  Widget build(

    BuildContext context,

  ) {

    return Scaffold(

      backgroundColor:

          const Color(0xFFFFF7FA),

      body: SafeArea(

        child: Padding(

          padding:

              const EdgeInsets.all(24),

          child: Column(

            mainAxisAlignment:

                MainAxisAlignment.center,

            children: [

              Container(

                width: 110,

                height: 110,

                decoration:

                    const BoxDecoration(

                  color:

                      Color(0xFFFFDCE9),

                  shape:

                      BoxShape.circle,

                ),

                child: const Icon(

                  Icons.check_circle_outline,

                  color:

                      Color(0xFFE91E63),

                  size: 65,

                ),

              ),



              const SizedBox(

                height: 28,

              ),



              const Text(

                'Meetup Successful!',

                textAlign:

                    TextAlign.center,

                style: TextStyle(

                  fontSize: 28,

                  fontWeight:

                      FontWeight.w800,

                  color:

                      Color(0xFF34262C),

                ),

              ),



              const SizedBox(

                height: 12,

              ),



              Text(

                'You and $otherUserName have connected at',

                textAlign:

                    TextAlign.center,

                style:

                    const TextStyle(

                  fontSize: 15,

                  color:

                      Color(0xFF806B74),

                ),

              ),



              const SizedBox(

                height: 8,

              ),



              Text(

                meetingPlace,

                textAlign:

                    TextAlign.center,

                style:

                    const TextStyle(

                  fontSize: 18,

                  fontWeight:

                      FontWeight.w700,

                  color:

                      Color(0xFFE91E63),

                ),

              ),



              const SizedBox(

                height: 35,

              ),



              Container(

                width: double.infinity,

                padding:

                    const EdgeInsets.all(20),

                decoration:

                    BoxDecoration(

                  color: Colors.white,

                  borderRadius:

                      BorderRadius.circular(22),

                ),

                child: const Column(

                  children: [

                    Icon(

                      Icons.route_outlined,

                      color:

                          Color(0xFFE91E63),

                      size: 35,

                    ),



                    SizedBox(

                      height: 12,

                    ),



                    Text(

                      'Ready for your next journey?',

                      textAlign:

                          TextAlign.center,

                      style:

                          TextStyle(

                        fontSize: 18,

                        fontWeight:

                            FontWeight.w700,

                        color:

                            Color(0xFF34262C),

                      ),

                    ),



                    SizedBox(

                      height: 6,

                    ),



                    Text(

                      'Choose somewhere to explore together.',

                      textAlign:

                          TextAlign.center,

                      style:

                          TextStyle(

                        fontSize: 14,

                        color:

                            Color(0xFF806B74),

                      ),

                    ),

                  ],

                ),

              ),



              const SizedBox(

                height: 25,

              ),



              SizedBox(

                width: double.infinity,

                height: 56,

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>

                            CombinedJourneyScreen(

                          otherUserName:

                              otherUserName,

                        ),

                      ),

                    );

                  },

                  style:

                      ElevatedButton.styleFrom(

                    backgroundColor:

                        const Color(

                      0xFFE91E63,

                    ),

                    foregroundColor:

                        Colors.white,

                    elevation: 0,

                    shape:

                        RoundedRectangleBorder(

                      borderRadius:

                          BorderRadius.circular(

                        18,

                      ),

                    ),

                  ),

                  child:

                      const Text(

                    'PLAN A COMBINED JOURNEY',

                    style:

                        TextStyle(

                      fontSize: 15,

                      fontWeight:

                          FontWeight.w700,

                      letterSpacing:

                          0.5,

                    ),

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



// ================================================================

// COMBINED JOURNEY SCREEN

// ================================================================



class CombinedJourneyScreen

    extends StatefulWidget {

  final String otherUserName;



  const CombinedJourneyScreen({

    super.key,

    required this.otherUserName,

  });



  @override

  State<CombinedJourneyScreen> createState() =>

      _CombinedJourneyScreenState();

}



class _CombinedJourneyScreenState

    extends State<CombinedJourneyScreen> {

  final TextEditingController

      destinationController =

      TextEditingController();



  @override

  void dispose() {

    destinationController.dispose();

    super.dispose();

  }



  void _planJourney() {

    final destination =

        destinationController.text.trim();



    if (destination.isEmpty) {

      ScaffoldMessenger.of(context)

          .showSnackBar(

        const SnackBar(

          content: Text(

            'Enter a destination first.',

          ),

        ),

      );



      return;

    }



    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text(

            'Journey Planned!',

          ),

          content: Text(

            'You and ${widget.otherUserName} are planning a journey to $destination.',

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text(

                'OK',

                style: TextStyle(

                  color:

                      Color(0xFFE91E63),

                ),

              ),

            ),

          ],

        );

      },

    );

  }



  @override

  Widget build(

    BuildContext context,

  ) {

    return Scaffold(

      backgroundColor:

          const Color(0xFFFFF7FA),



      appBar: AppBar(

        backgroundColor:

            Colors.transparent,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(

            Icons.arrow_back,

            color:

                Color(0xFF34262C),

          ),

          onPressed: () {

            Navigator.pop(context);

          },

        ),

        title: const Text(

          'Plan Together',

          style: TextStyle(

            color:

                Color(0xFF34262C),

            fontWeight:

                FontWeight.w700,

          ),

        ),

      ),



      body: Padding(

        padding:

            const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment:

              CrossAxisAlignment.start,

          children: [

            const SizedBox(

              height: 30,

            ),



            const Text(

              'Where should we go?',

              style: TextStyle(

                fontSize: 28,

                fontWeight:

                    FontWeight.w800,

                color:

                    Color(0xFF34262C),

              ),

            ),



            const SizedBox(

              height: 10,

            ),



            Text(

              'Plan your next journey with ${widget.otherUserName}.',

              style:

                  const TextStyle(

                fontSize: 15,

                color:

                    Color(0xFF806B74),

              ),

            ),



            const SizedBox(

              height: 30,

            ),



            TextField(

              controller:

                  destinationController,

              decoration:

                  InputDecoration(

                hintText:

                    'Enter destination',

                prefixIcon:

                    const Icon(

                  Icons.location_on_outlined,

                  color:

                      Color(0xFFE91E63),

                ),

                filled: true,

                fillColor:

                    Colors.white,

                border:

                    OutlineInputBorder(

                  borderRadius:

                      BorderRadius.circular(

                    18,

                  ),

                  borderSide:

                      BorderSide.none,

                ),

              ),

            ),



            const SizedBox(

              height: 20,

            ),



            SizedBox(

              width: double.infinity,

              height: 56,

              child:

                  ElevatedButton(

                onPressed:

                    _planJourney,

                style:

                    ElevatedButton.styleFrom(

                  backgroundColor:

                      const Color(

                    0xFFE91E63,

                  ),

                  foregroundColor:

                      Colors.white,

                  elevation: 0,

                  shape:

                      RoundedRectangleBorder(

                    borderRadius:

                        BorderRadius.circular(

                      18,

                    ),

                  ),

                ),

                child:

                    const Text(

                  'PLAN JOURNEY',

                  style:

                      TextStyle(

                    fontWeight:

                        FontWeight.w700,

                    letterSpacing:

                        0.5,

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}