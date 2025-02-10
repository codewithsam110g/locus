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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchRadiusFromDatabase();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final user_id = supabase.auth.currentUser!.id;

    await supabase.from("profile").update({
      "last_loc": {
        "lat": position.latitude,
        "long": position.longitude,
      }
    }).eq("user_id", user_id);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchRadiusFromDatabase() async {
    final user_id = supabase.auth.currentUser!.id;
    final response = await supabase.from('profile').select('range').eq('user_id', user_id).maybeSingle();
    final range = response?['range'];

    setState(() {
      if (range != null && range is double) {
        _selectedRadius = range;
      }
    });
  }

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
      }
    });
  }

  Future<void> _updateRadiusInDatabase(double radius) async {
    final user_id = supabase.auth.currentUser!.id;
    await supabase.from('profile').update({'range': radius}).eq('user_id', user_id);
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
                  Navigator.of(context).push(MaterialPageRoute(builder: (builder) => Profile()));
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
                          onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                        ),
                      ],
                    ),
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
                            Icon(Icons.radio_button_checked, color: Colors.black, size: 20),
                            SizedBox(width: 10),
                            Text('$_selectedRadius m', style: TextStyle(color: Colors.black, fontSize: 16)),
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
