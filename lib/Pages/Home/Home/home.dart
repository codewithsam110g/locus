import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:locus/Pages/Home/Home/profile.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  LatLng? _currentLocation;
  double _selectedRadius = 200.0;
  Timer? _debounceTimer;
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _communityMarkers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchRadiusFromDatabase();
    _subscribeToCommunityUpdates();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final userId = supabase.auth.currentUser!.id;
    await supabase.from("profile").update({
      "last_loc": {"lat": position.latitude, "long": position.longitude},
    }).eq("user_id", userId);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _fetchCommunities();
  }

  Future<void> _fetchRadiusFromDatabase() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('profile')
        .select('range')
        .eq('user_id', userId)
        .maybeSingle();
    final range = response?['range'];
    setState(() {
      if (range != null && range is double) _selectedRadius = range;
    });
    _fetchCommunities();
  }

  void _updateRadiusDebounced(double radius) {
    setState(() {
      _selectedRadius = radius;
    });

    _debounceTimer?.cancel(); // Cancel any previous timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateRadius(radius);
    });
  }

  Future<void> _updateRadius(double radius) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from("profile")
        .update({"range": radius}).eq("user_id", userId);
    _fetchCommunities();
  }

  void _subscribeToCommunityUpdates() {
    supabase.from('community').stream(primaryKey: ['id']).listen((event) {
      _fetchCommunities();
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
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

  Future<void> _fetchCommunities() async {
    if (_currentLocation == null) return;
    final response = await supabase.from('community').select();
    List<dynamic> communities = response;
    List<Map<String, dynamic>> filteredMarkers = [];
    for (var community in communities) {
      if (community['location'] == null || community['accepted'] != true) {
        continue;
      }
      final loc = community['location'];
      final double communityLat = (loc['lat'] as num).toDouble();
      final double communityLong = (loc['long'] as num).toDouble();
      double distance = _calculateDistance(_currentLocation!.latitude,
          _currentLocation!.longitude, communityLat, communityLong);
      if (distance <= _selectedRadius) {
        filteredMarkers.add({
          'title': community['title'] ?? 'Community',
          'lat': communityLat,
          'long': communityLong
        });
      }
    }
    setState(() {
      _communityMarkers = filteredMarkers;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Dispose of the timer when widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Image.asset('assets/img/locusw.png', width: 170),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await _getCurrentLocation();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (builder) => const Profile()));
            },
          ),
        ],
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Current Radius: ${_selectedRadius.toInt()} meters",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Slider(
                  value: _selectedRadius,
                  min: 100.0,
                  max: 2000.0,
                  divisions: 19,
                  label: "${_selectedRadius.toInt()}m",
                  onChanged: (value) {
                    _updateRadiusDebounced(value);
                  },
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentLocation!,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          // User's current location marker (red)
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: const Tooltip(
                              message: "Your Location",
                              child: Icon(Icons.location_on, size: 40, color: Colors.red),
                            ),
                          ),
                          // Community markers (green)
                          ..._communityMarkers.map((community) => Marker(
                                point: LatLng(community['lat'], community['long']),
                                width: 40,
                                height: 40,
                                child: Tooltip(
                                  message: community['title'],
                                  child: const Icon(Icons.location_on, size: 40, color: Colors.green),
                                ),
                              )),
                        ],
                      ),
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
