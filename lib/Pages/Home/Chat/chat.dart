import 'dart:math';
import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/Pages/Home/Chat/message.dart';
import 'package:locus/Pages/Home/Chat/notifications.dart';
import 'package:locus/widgets/Buttons/InnerButton.dart';
import 'package:locus/widgets/Buttons/OuterButton.dart';
import 'package:locus/widgets/chatContainer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Chat extends StatefulWidget {
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> chats = [];

  // Default current user's location values.
  double currentUserLat = 16.7930;
  double currentUserLong = 80.8225;

  // Maximum distance (in meters) for a message to be visible.
  double distanceThreshold = 10000.0; // e.g., 10 kilometers

  @override
  void initState() {
    super.initState();
    _setLocation();
    _fetchMessages();
    _listenForUpdates();
  }

  /// Retrieves the current user's location settings from their profile.
  Future<void> _setLocation() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('profile')
        .select("last_loc, range")
        .eq("user_id", userId)
        .single();

    setState(() {
      currentUserLat = data["last_loc"]["lat"] as double;
      currentUserLong = data["last_loc"]["long"] as double;
      distanceThreshold = double.parse(data["range"].toString());
    });
  }

  /// Deletes messages older than 24 hours.
  Future<void> _deleteOldMessages() async {
    final threshold =
        DateTime.now().toUtc().subtract(const Duration(hours: 24));
    await supabase
        .from("messages")
        .delete()
        .lt("created_at", threshold.toIso8601String());
  }

  /// Fetches messages from Supabase and filters them based on location.
  Future<void> _fetchMessages() async {
    // Delete messages older than 24 hours.
    await _deleteOldMessages();

    // Fetch messages with the sender's profile (including name) and location.
    final response = await supabase
        .from("messages")
        .select(
            "message, user_id, created_at, profile(name), location, created_at")
        .order("id");

    // Filter messages based on the sender's location.
    final filteredMessages = response.where((message) {
      final profile = message['profile'];
      if (profile == null || message['location'] == null) return false;
      final loc = message['location'];
      final double senderLat = loc['lat'] is num
          ? loc['lat'].toDouble()
          : double.tryParse(loc['lat'].toString()) ?? 0;
      final double senderLong = loc['lng'] is num
          ? loc['lng'].toDouble()
          : double.tryParse(loc['lng'].toString()) ?? 0;
      final double distance = calculateDistance(
          currentUserLat, currentUserLong, senderLat, senderLong);
      return distance <= distanceThreshold;
    }).toList();

    final currentUserId = supabase.auth.currentUser!.id;

    setState(() {
      chats = filteredMessages.map<Map<String, dynamic>>((message) {
        DateTime dateTime = DateTime.parse(message["created_at"]).toLocal();
        String formattedDateTime =
            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} "
            "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
        return {
          // For the new UI we generate an avatar based on the name.
          'name': message['profile']['name'] ?? 'Unknown',
          'text': message['message'],
          // If the message's user_id matches the current user's id, mark it as 'send'
          'type': message['user_id'] == currentUserId ? 'send' : 'receive',
          // For now, assume all chats are accepted.
          'isAccept': 'true',
          "created_at": formattedDateTime
        };
      }).toList();
    });
  }

  /// Listens for real-time updates on the messages table.
  void _listenForUpdates() {
    supabase.from("messages").stream(primaryKey: ["id"]).listen((data) {
      _fetchMessages();
    });
  }

  /// Calculates the distance (in meters) between two geographic coordinates
  /// using the Haversine formula.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  /// Displays a request dialog when the chat isn't accepted.
  void _showRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
            'You need to send a request to start a conversation with this user. Would you like to proceed?'),
        actions: [
          Row(
            children: [
              Outerbutton(text: 'Cancel'),
              const SizedBox(width: 10),
              Innerbutton(
                function: () {
                  Navigator.of(context).pop();
                },
                text: 'Request',
              )
            ],
          )
        ],
      ),
    );
  }

  /// Builds a circular avatar widget with a background color chosen from a fixed set
  /// (based on the sender’s name hash) and displays the first character of the name.
  Widget buildAvatar(String name) {
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final Color bgColor = colors[name.hashCode % colors.length];
    return CircleAvatar(
      backgroundColor: bgColor,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Text(
            'Message',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Electrolize',
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (builder) => Notifications()),
                );
              },
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Chat list.
          Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 15, bottom: 80),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final bool isAccept = chat['isAccept'] == 'true';

                      return Chatcontainer(
                        type: chat['type'] as String,
                        // Instead of using a static image, we generate an avatar.
                        avatar: buildAvatar(chat['name'] as String),
                        name: chat['name'] as String,
                        text: chat['text'] as String,
                        date: chat["created_at"] as String,
                        // For now, always set isActive to true.
                        isActive: true,
                        function: () {
                          if (!isAccept) {
                            _showRequest(context);
                          } else {
                            // Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (builder) => Chatinterface(
                            //       name: chat['name'] as String,
                            //       avatar: buildAvatar(chat['name'] as String),
                            //     ),
                            //   ),
                            // );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Floating action button to compose a new message.
          Positioned(
            bottom: 100,
            right: 30,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.9,
                    minChildSize: 0.5,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Message(), // Your message composition widget.
                      );
                    },
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
