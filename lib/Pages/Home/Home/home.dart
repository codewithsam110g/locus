import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:locus/Pages/Home/Explore/userView.dart';
import 'package:locus/Pages/Home/Home/profile.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  LatLng? _currentLocation;
  double _selectedRadius = 200.0;
  Timer? _debounceTimer;
  bool _showRadiusSlider = false;
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _communityMarkers = [];

  // Error state tracking
  bool _isLoading = true;
  String? _errorMessage;
  bool _isNetworkAvailable = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _setupConnectivityListener();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Don't rely on connectivity check to block operations
      // Instead, let the operations run and handle network failures appropriately
      await _getCurrentLocation();
      await _fetchRadiusFromDatabase();
      _subscribeToCommunityUpdates();
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final String errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('internet')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error is LocationServiceDisabledException) {
      return 'Location services are disabled. Please enable location in your device settings.';
    } else if (error is PermissionDeniedException) {
      return 'Location permission denied. Please allow location access in app settings.';
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final bool wasConnected = _isNetworkAvailable;
      final bool isConnected = !results.contains(ConnectivityResult.none);

      setState(() {
        _isNetworkAvailable = isConnected;
      });

      // If connection was restored, retry initialization
      if (!wasConnected && isConnected) {
        // Show a message that we're reconnected
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Internet connection restored. Refreshing data..."),
              backgroundColor: Colors.green,
            ),
          );
        }
        _initialize();
      } else if (wasConnected && !isConnected) {
        // Show a message that we lost connection
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Internet connection lost. Some features may be unavailable."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _toggleRadiusSlider() {
    setState(() {
      _showRadiusSlider = !_showRadiusSlider;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw PermissionDeniedException();
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final userId = supabase.auth.currentUser!.id;
      await supabase.from("profile").update({
        "last_loc": {"lat": position.latitude, "long": position.longitude},
      }).eq("user_id", userId);

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      await _fetchCommunities();
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception("Location request timed out. Please try again.");
      } else {
        throw e;
      }
    }
  }

  Future<void> _fetchRadiusFromDatabase() async {
    try {
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
    } catch (e) {
      // Continue with default radius if this fails
      print("Error fetching radius: $e");
    }
  }

  void _updateRadiusDebounced(double radius) {
    setState(() {
      _selectedRadius = radius;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateRadius(radius);
    });
  }

  Future<void> _updateRadius(double radius) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase
          .from("profile")
          .update({"range": radius}).eq("user_id", userId);
      await _fetchCommunities();
    } catch (e) {
      // Show a snackbar but don't interrupt the flow
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update radius: ${e.toString()}")),
        );
      }
    }
  }

  void _subscribeToCommunityUpdates() {
    try {
      supabase.from('community').stream(primaryKey: ['id']).listen((event) {
        _fetchCommunities();
      });
    } catch (e) {
      print("Error subscribing to community updates: $e");
      // Non-critical, can continue without real-time updates
    }
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

    try {
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
            'id': community['id'] ?? '',
            'title': community['title'] ?? 'Community',
            'lat': communityLat,
            'long': communityLong,
            'com_id': community['com_id'],
            'logo_link': community['logo_link'] ?? '',
          });
        }
      }

      setState(() {
        _communityMarkers = filteredMarkers;
      });
    } catch (e) {
      print("Error fetching communities: $e");
      // Check if it's a network error and update the UI accordingly
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        setState(() {
          _isNetworkAvailable = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to load communities: ${e.toString().split('\n')[0]}")),
        );
      }
    }
  }

  void _onMarkerTap(String comId, String name, String imgUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            Userview(id: comId, name: name, profilePicUrl: imgUrl),
      ),
    );
  }

  void _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  void _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Image.asset('assets/img/locusw.png', width: 170),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _initialize,
          ),
          IconButton(
            onPressed: _isNetworkAvailable ? _toggleRadiusSlider : null,
            icon: Icon(
              Icons.location_on,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (builder) => const Profile()));
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading map and location data...'),
                ],
              ),
            )
          else if (_errorMessage != null)
            _buildErrorView()
          else if (_currentLocation == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Unable to get your location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _initialize,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentLocation!,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        errorImage: const NetworkImage(
                          'https://cdn-icons-png.flaticon.com/512/1548/1548682.png',
                        ),
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
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: const Tooltip(
                              message: "Your Location",
                              child: Icon(Icons.location_on,
                                  size: 40, color: Colors.red),
                            ),
                          ),
                          ..._communityMarkers.map((community) => Marker(
                                point:
                                    LatLng(community['lat'], community['long']),
                                width: 80,
                                height: 70,
                                child: GestureDetector(
                                  onTap: () => _onMarkerTap(
                                    community['com_id'],
                                    community['title'],
                                    community['logo_link'],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 40,
                                        color: Colors.green,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border:
                                              Border.all(color: Colors.green),
                                        ),
                                        child: Text(
                                          community['title'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: _showRadiusSlider && _currentLocation != null ? 10 : -150,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Current Radius: ${_selectedRadius.toInt()} meters",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                ],
              ),
            ),
          ),
          if (!_isNetworkAvailable && !_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.red,
                child: const Text(
                  'No internet connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    IconData iconData;
    String title;
    String message = _errorMessage ?? 'An unknown error occurred';
    List<Widget> actions = [
      ElevatedButton(
        style:
            ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
        onPressed: _initialize,
        child: const Text('Try Again'),
      ),
    ];

    if (message.contains('internet connection')) {
      iconData = Icons.wifi_off;
      title = 'No Internet Connection';
    } else if (message.contains('Location services are disabled')) {
      iconData = Icons.location_off;
      title = 'Location Services Disabled';
      actions.add(
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ), // ✅ Border color
          ),
          onPressed: _openLocationSettings,
          child: const Text('Open App Settings'),
        ),
      );
    } else if (message.contains('Location permission denied')) {
      iconData = Icons.not_listed_location;
      title = 'Location Permission Required';
      actions.add(
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ), // ✅ Border color
          ),
          onPressed: _openAppSettings,
          child: const Text('Open App Settings'),
        ),
      );
    } else {
      iconData = Icons.error_outline;
      title = 'Error';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 70, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions.map((widget) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: widget,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Location services are disabled.';
}

class PermissionDeniedException implements Exception {
  @override
  String toString() => 'Location permission denied.';
}
