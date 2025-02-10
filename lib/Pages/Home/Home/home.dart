import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:locus/Pages/Home/Home/profile.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  LatLng? _currentLocation;
  double _selectedRadius = 200.0;
  final supabase = Supabase.instance.client;

  // List to hold community marker data (each with a title, latitude, and longitude).
  List<Map<String, dynamic>> _communityMarkers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchRadiusFromDatabase();
  }

  /// Gets the current location, updates the profile with it, and then fetches communities.
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Optionally, show a message to the user.
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Optionally, show a message to the user.
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final user_id = supabase.auth.currentUser!.id;

    // Update the user's last known location in the database.
    await supabase.from("profile").update({
      "last_loc": {
        "lat": position.latitude,
        "long": position.longitude,
      }
    }).eq("user_id", user_id);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    // After the current location is set, fetch the nearby communities.
    _fetchCommunities();
  }

  /// Fetches the user's preferred radius from the database.
  Future<void> _fetchRadiusFromDatabase() async {
    final user_id = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('profile')
        .select('range')
        .eq('user_id', user_id)
        .maybeSingle();
    final range = response?['range'];

    setState(() {
      if (range != null && range is double) {
        _selectedRadius = range;
      }
    });

    // Fetch communities if the radius changed.
    _fetchCommunities();
  }

  /// Displays a popup menu to select the radius.
  void _showRadiusDropdown(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(200, 155, 20, 0),
      items: [
        PopupMenuItem(value: 200.0, child: Text('200m')),
        PopupMenuItem(value: 300.0, child: Text('300m')),
        PopupMenuItem(value: 400.0, child: Text('400m')),
        PopupMenuItem(value: 600.0, child: Text('600m')),
        PopupMenuItem(value: 1000.0, child: Text('1000m')),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedRadius = value;
        });
        _updateRadiusInDatabase(value);
        // Re-fetch communities when the radius changes.
        _fetchCommunities();
      }
    });
  }

  /// Updates the radius in the user's profile.
  Future<void> _updateRadiusInDatabase(double radius) async {
    final user_id = supabase.auth.currentUser!.id;
    await supabase
        .from('profile')
        .update({'range': radius})
        .eq('user_id', user_id);
  }

  /// Calculates the distance (in meters) between two geographic coordinates using the Haversine formula.
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth's radius in meters.
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Fetches communities from Supabase and updates the marker list if they are within the selected radius.
  Future<void> _fetchCommunities() async {
    if (_currentLocation == null) return;

    // Fetch all community records.
    final response = await supabase.from('community').select();
    // Assume the response is a List<dynamic> of community records.
    List<dynamic> communities = response;
    List<Map<String, dynamic>> filteredMarkers = [];

    for (var community in communities) {
      // Ensure the community has a location and that it is accepted (adjust if needed).
      if (community['location'] == null || community['accepted'] != true) continue;

      final loc = community['location'];
      final double communityLat = loc['lat'] is num
          ? (loc['lat'] as num).toDouble()
          : double.tryParse(loc['lat'].toString()) ?? 0;
      final double communityLong = loc['long'] is num
          ? (loc['long'] as num).toDouble()
          : double.tryParse(loc['long'].toString()) ?? 0;

      // Calculate the distance from the user's current location.
      double distance = _calculateDistance(_currentLocation!.latitude,
          _currentLocation!.longitude, communityLat, communityLong);
      if (distance <= _selectedRadius) {
        filteredMarkers.add({
          'title': community['title'] ?? 'Community',
          'lat': communityLat,
          'long': communityLong,
        });
      }
    }

    setState(() {
      _communityMarkers = filteredMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Image.asset('assets/img/locusw.png', width: 170),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (builder) => Profile()));
                },
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLocation!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => launchUrl(Uri.parse(
                              'https://openstreetmap.org/copyright')),
                        ),
                      ],
                    ),
                    // Marker for the current user's location.
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_pin, size: 40, color: Colors.red),
                        ),
                      ],
                    ),

                    // Circle showing the selected radius.
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentLocation!,
                          color: Colors.blue.withOpacity(0.3),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                          useRadiusInMeter: true,
                          radius: _selectedRadius,
                        ),
                      ],
                    ),
                    // Marker layer for community pins.
                    MarkerLayer(
                      markers: _communityMarkers.map((community) {
                        return Marker(
                          point: LatLng(community['lat'], community['long']),
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: community['title'],
                            child: Icon(Icons.location_on, size: 40, color: Colors.green),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Radius selector positioned at the top-right.
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _showRadiusDropdown(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.radio_button_checked,
                                color: Colors.black, size: 20),
                            SizedBox(width: 10),
                            Text('$_selectedRadius m',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
