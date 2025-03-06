import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chat.dart';
import 'package:locus/Pages/Home/Explore/explore.dart';
import 'package:locus/Pages/Home/Home/home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Mainscreen extends StatefulWidget {
  @override
  _MainscreenState createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  int _selectedIndex = 1;
  int unseenCount = 0;

  final List<Widget> _pages = [
    Explore(),
    Home(),
    Chat(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      if (index == 2) {
        unseenCount = 0;
      }
      _selectedIndex = index; // Update the selected tab index
    });
  }

  Future<void> setFcmToken(String? token) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from("profile")
        .update({"fcm_token": token}).eq("user_id", userId);
  }

  void doStuff() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await setFcmToken(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notif = payload.notification;
      if (notif != null) {
        setState(() {
          unseenCount++; // Increase unseen message count
        });
      }
    });
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

  @override
  void initState() {
    super.initState();
    doStuff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Display the currently selected page
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          // Custom bottom navigation bar using Stack and Positioned
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                // color: Color(0xFFF7FEE7),
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.explore, 'Explore', 0),
                  _buildNavItem(Icons.home, 'Home', 1),
                  _buildNavItem(Icons.forum, 'Chat', 2, unseenCount),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      [int count = 0]) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Stack(
        clipBehavior: Clip.none, // Ensure badge is not clipped
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color:
                    isSelected ? Colors.white : Colors.black.withOpacity(0.6),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : Colors.black.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (count > 0 && index == 2) // Show badge only for Chat
            Positioned(
              top: -5, // Move slightly above the icon
              right: -5, // Move slightly to the right
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
