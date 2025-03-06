import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/Pages/Home/Chat/message.dart';
import 'package:locus/Pages/Home/Chat/notifications.dart';
import 'package:locus/widgets/Buttons/InnerButton.dart';
import 'package:locus/widgets/Buttons/OuterButton.dart';
import 'package:locus/widgets/chatContainer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> chats = [];
  bool isLoading = false;

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
    _listenForLocationUpdates();
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

  /// Listens for real-time updates on the user's location in profile table
  void _listenForLocationUpdates() {
    final userId = supabase.auth.currentUser!.id;

    supabase
        .from('profile')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final userData = data.first;
            final newLat = userData["last_loc"]["lat"] as double;
            final newLong = userData["last_loc"]["long"] as double;
            final newRange = double.parse(userData["range"].toString());

            // Check if location or range has changed
            if (newLat != currentUserLat ||
                newLong != currentUserLong ||
                newRange != distanceThreshold) {
              setState(() {
                currentUserLat = newLat;
                currentUserLong = newLong;
                distanceThreshold = newRange;
              });

              // Reload messages when location changes
              _fetchMessages();
            }
          }
        });
  }

  Future<void> _fetchMessages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUserId = supabase.auth.currentUser!.id;

      // Call stored procedure in Supabase to get nearby messages
      // Using the current location values stored in the state
      final response = await supabase.rpc('get_nearby_messages', params: {
        'lat': currentUserLat,
        'long': currentUserLong,
        'max_distance': distanceThreshold
      });

      // Fetch request data for the current user (involving any other user)
      final requestsData = await supabase
          .from('requests')
          .select('requested_uid, reciever_uid, status')
          .or('requested_uid.eq.$currentUserId,reciever_uid.eq.$currentUserId');

      // Update state with messages and determine isActive status using requests table
      if (mounted) {
        setState(() {
          chats = response.map<Map<String, dynamic>>((message) {
            DateTime dateTime = DateTime.parse(message["created_at"]).toLocal();
            String formattedDateTime =
                "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} "
                "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
            // The other user's id (person we want to chat with)
            String otherId = message['user_id'];

            // Determine the request status between currentUserId and otherId.
            String requestStatus = "";
            if (requestsData != null) {
              for (var req in requestsData) {
                if ((req['requested_uid'] == currentUserId &&
                        req['reciever_uid'] == otherId) ||
                    (req['requested_uid'] == otherId &&
                        req['reciever_uid'] == currentUserId)) {
                  requestStatus = req['status'];
                  break;
                }
              }
            }

            // Set isActive based on request status.
            String isActive;
            if (requestStatus.isNotEmpty) {
              if (requestStatus == 'pending') {
                isActive = "pending";
              } else if (requestStatus == 'accept') {
                isActive = "true";
              } else {
                isActive = "false";
              }
            } else {
              isActive = "false";
            }

            return {
              'name': message['name'] ?? 'Unknown',
              'text': message['message'],
              'type': message['user_id'] == currentUserId ? 'send' : 'receive',
              'isActive': isActive,
              'created_at': formattedDateTime,
              'uid': otherId
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching messages: ${e.toString()}")),
        );
      }
    }
  }

  /// Listens for real-time updates on the messages table.
  void _listenForUpdates() {
    supabase.from("messages").stream(primaryKey: ["id"]).listen((data) {
      _fetchMessages();
    });
  }

  void _showRequest(BuildContext context, String recipientUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: const Text(
            'You need to send a request to start a conversation with this user. Would you like to proceed?'),
        actions: [
          Row(
            children: [
              const Outerbutton(text: 'Cancel'),
              const SizedBox(width: 10),
              Innerbutton(
                function: () async {
                  Navigator.of(context).pop();
                  await _sendChatRequest(recipientUserId);
                },
                text: 'Request',
              )
            ],
          )
        ],
      ),
    );
  }

  Future<void> _sendChatRequest(String recipientUserId) async {
    final currentUserId = supabase.auth.currentUser!.id;
    await supabase.from('requests').insert({
      'requested_uid': currentUserId,
      'reciever_uid': recipientUserId,
      'status': 'pending',
      'action_by': currentUserId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Show confirmation message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent successfully!")),
      );
    }
  }

  /// Builds a circular avatar widget with a background color chosen from a fixed set
  /// (based on the sender's name hash) and displays the first character of the name.
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
          // Refresh button
          GestureDetector(
            onTap: () {
              if (!isLoading) {
                _fetchMessages();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Refreshing messages...")),
                );
              }
            },
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ))
                : const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
          ),
          SizedBox(
            width: 15,
          ),
          // Notifications button
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (builder) => Notifications()),
                );
              },
              icon: Icon(
                Icons.chat,
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
                  child: isLoading && chats.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : chats.isEmpty
                          ? const Center(
                              child: Text(
                                  'No messages nearby. Try adjusting your range.'),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await _fetchMessages();
                              },
                              child: ListView.builder(
                                itemCount: chats.length,
                                itemBuilder: (context, index) {
                                  final chat = chats[index];
                                  final bool isAccept =
                                      chat['isActive'] == "true";
                                  return Chatcontainer(
                                    type: chat['type'] as String,
                                    // Instead of using a static image, we generate an avatar.
                                    avatar: buildAvatar(chat['name'] as String),
                                    name: chat['name'] as String,
                                    text: chat['text'] as String,
                                    date: chat["created_at"] as String,
                                    function: () {
                                      if (chat['isActive'] == "pending") {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "You have a pending Request with the user!")),
                                        );
                                      } else if (!isAccept) {
                                        _showRequest(context, chat['uid']);
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (builder) => Chatinterface(
                                              id: chat['uid'] as String,
                                              avatar: buildAvatar(
                                                  chat['name'] as String),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
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
                    initialChildSize: 0.8,
                    maxChildSize: 0.8,
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
