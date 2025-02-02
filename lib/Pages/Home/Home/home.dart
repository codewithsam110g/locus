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
  final supabase = Supabase.instance.client;
  var range = 500.0;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    getRange();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> getRange() async {
    final user_id = supabase.auth.currentUser!.id;
    final prof = await supabase
        .from('profile')
        .select("range")
        .eq("user_id", user_id)
        .maybeSingle();
    final rge = prof!['range'];

    setState(() {
      if(rge is int){
        range = toDouble(rge) ?? 500.0;
      }else {
        range = toDouble(rge) ?? 500.0;
      }
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
                    MaterialPageRoute(builder: (builder) => Profile()),
                  );
                },
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: _currentLocation == null
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading until location is obtained
          : FlutterMap(
              options: MapOptions(
                initialCenter:
                    _currentLocation!, // Center map at user's location
                initialZoom: 15.0, // Closer zoom for better visibility
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
                      onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
                // 🔹 Marker for user's location
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child:
                          Icon(Icons.location_pin, size: 40, color: Colors.red),
                    ),
                  ],
                ),
                // 🔹 Circle to show 500m radius
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation!,
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                      radius: range, // 500m radius
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
