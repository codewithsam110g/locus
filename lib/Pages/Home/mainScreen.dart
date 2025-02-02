import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locus/Pages/Home/Chat/chat.dart';
import 'package:locus/Pages/Home/Explore/explore.dart';
import 'package:locus/Pages/Home/Home/home.dart';

class Mainscreen extends StatefulWidget {
  @override
  _MainscreenState createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  int _selectedIndex = 1;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final List<Widget> _pages = [
    Explore(),
    Home(),
    Chat(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Permission granted");
    } else {
      print("Permission denied");
    }
  }

  Future<void> setFcmToken(String? token) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from("profile")
        .update({"fcm_token": token}).eq("user_id", userId);
  }

  Future<void> getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
    await setFcmToken(token);
  }

  @override
  void initState() {
    super.initState();
    doStuff();
  }

  void _showPopupDialog(String? title, String? body) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? "New Notification"),
          content: Text(body ?? "You have received a new message."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void doStuff() async {
    await requestPermission();
    await getFCMToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await setFcmToken(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notif = payload.notification;
      if (notif != null) {
        _showPopupDialog(notif.title, notif.body);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key:
          _scaffoldMessengerKey, // Attach the key here (if needed for other use cases)
      child: Scaffold(
        body: Stack(
          children: [
            // Display the currently selected page
            _pages[_selectedIndex],
            // Custom bottom navigation bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.explore, 'Explore', 0),
                    _buildNavItem(Icons.home, 'Home', 1),
                    _buildNavItem(Icons.forum, 'Chat', 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Icon(
              icon,
              size: 40,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
