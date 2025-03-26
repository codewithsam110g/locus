import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/Pages/Home/Chat/message.dart';
import 'package:locus/Pages/Home/Chat/notifications.dart';
import 'package:locus/widgets/Buttons/InnerButton.dart';
import 'package:locus/widgets/Buttons/OuterButton.dart';
import 'package:locus/widgets/chatContainer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Add this dependency for location services

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> chats = [];
  bool isLoading = false;
  bool isLocationEnabled = true;

  // Default current user's location values.
  double currentUserLat = 16.7930;
  double currentUserLong = 80.8225;

  // Maximum distance (in meters) for a message to be visible.
  double distanceThreshold = 10000.0; // e.g., 10 kilometers

  bool _isNetworkAvailable = true;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _locationSubscription;
  int _retryCount = 0;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _setupConnectivityListener();
    _checkLocationPermission();
    _fetchData();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _messagesSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
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
        _fetchData();
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

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            isLocationEnabled = false;
            _hasLocationPermission = false;
          });
        }
        _showLocationDialog("Location services are disabled",
            "Please enable location services to view nearby messages.", true);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _hasLocationPermission = false;
            });
            _showLocationDialog(
                "Location permission denied",
                "Location permission is required to view nearby messages.",
                false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _hasLocationPermission = false;
          });
          _showLocationDialog("Location permission denied permanently",
              "Please enable location permission in app settings.", false);
        }
        return;
      }

      // If we reach here, we have the permission
      if (mounted) {
        setState(() {
          isLocationEnabled = true;
          _hasLocationPermission = true;
        });
      }
    } catch (e) {
      print("Error checking location permission: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Error accessing location: ${e.toString().split('\n')[0]}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationDialog(String title, String message, bool isServiceIssue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkLocationPermission();
              },
            ),
            TextButton(
              child: Text(isServiceIssue ? 'Open Settings' : 'Continue Anyway'),
              onPressed: () {
                Navigator.of(context).pop();
                if (isServiceIssue) {
                  Geolocator.openLocationSettings();
                } else {
                  // Proceed with limited functionality
                  _fetchData();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _fetchData() {
    _setLocation().then((_) {
      _fetchMessages();
      _listenForUpdates();
      _listenForLocationUpdates();
    }).catchError((error) {
      // If _setLocation fails, still try to fetch messages with default values
      print("Error in location setup: $error, using default location");
      _fetchMessages();
      _listenForUpdates();
    });
  }

  /// Retrieves the current user's location settings from their profile.
  Future<void> _setLocation() async {
    try {
      // Check if network is available
      if (!_isNetworkAvailable) {
        throw Exception("No internet connection");
      }

      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profile')
          .select("last_loc, range")
          .eq("user_id", userId)
          .single();

      if (mounted) {
        setState(() {
          // Safely handle potential null or invalid values
          try {
            if (data["last_loc"] != null) {
              currentUserLat = data["last_loc"]["lat"] as double;
              currentUserLong = data["last_loc"]["long"] as double;
            }

            if (data["range"] != null) {
              distanceThreshold = double.parse(data["range"].toString());
            }
          } catch (e) {
            print("Error parsing location data: $e");
            // Keep default values
          }
        });
      }
    } catch (e) {
      print("Error setting location: $e");
    }
  }

  Future<void> _fetchMessages() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Check for connectivity first
      if (!_isNetworkAvailable) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "No internet connection. Using cached data if available.")),
          );
        }
        return;
      }

      final currentUserId = supabase.auth.currentUser!.id;

      // Call stored procedure in Supabase to get nearby messages
      final response = await supabase.rpc('get_nearby_messages', params: {
        'lat': currentUserLat,
        'long': currentUserLong,
        'max_distance': distanceThreshold
      }).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException("Request timed out. Please try again.");
      });

      // Reset retry count on success
      _retryCount = 0;

      // Fetch request data for the current user
      final requestsData = await supabase
          .from('requests')
          .select('requested_uid, reciever_uid, status')
          .or('requested_uid.eq.$currentUserId,reciever_uid.eq.$currentUserId');

      // Process messages and fetch photo URLs BEFORE setState
      List<Map<String, dynamic>> processedChats = [];
      for (var message in response) {
        DateTime dateTime = DateTime.parse(message["created_at"]).toLocal();
        String formattedDateTime =
            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} "
            "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";

        // The other user's id
        String otherId = message['user_id'];

        // Fetch photo URL outside of setState
        String photoURL = '';
        try {
          var resp = await supabase
              .from("profile")
              .select("image_link")
              .eq("user_id", otherId)
              .single();
          photoURL =
              resp['image_link'] != null ? resp['image_link'] as String : '';
        } catch (e) {
          // Continue with empty photo URL if this specific request fails
          print("Error fetching photo for user $otherId: $e");
        }

        // Determine the request status
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

        // Set isActive based on request status
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

        processedChats.add({
          'name': message['name'] ?? 'Unknown',
          'text': message['message'],
          'type': message['user_id'] == currentUserId ? 'send' : 'receive',
          'isActive': isActive,
          'created_at': formattedDateTime,
          'uid': otherId,
          'image_link': photoURL
        });
      }

      // Now update the state with the fully processed data
      if (mounted) {
        setState(() {
          chats = processedChats;
          isLoading = false;
        });
      }
    } catch (e) {
      final String errorMessage = e.toString();
      print("Error fetching messages: $errorMessage");

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // Update network availability if it's a network error
        final String errorString = errorMessage.toLowerCase();
        if (errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('socket') ||
            errorString.contains('timeout') ||
            errorString.contains('internet')) {
          setState(() {
            _isNetworkAvailable = false;
          });
        }

        // Handle specific RPC error (get_nearby_messages function)
        if (errorString.contains('get_nearby_messages')) {
          _showRetryDialog(
              "Error loading nearby messages",
              "There was a problem with the location-based service. Please check your location settings and try again.",
              _fetchMessages);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Error fetching messages: ${errorMessage.split('\n')[0]}"),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  _fetchMessages();
                },
              ),
            ),
          );
        }

        // Implement exponential backoff for automatic retries
        if (_retryCount < 3) {
          _retryCount++;
          Future.delayed(Duration(seconds: _retryCount * 2), () {
            if (mounted) {
              _fetchMessages();
            }
          });
        }
      }
    }
  }

  void _showRetryDialog(String title, String message, Function retryFunction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                retryFunction();
              },
            ),
            if (!isLocationEnabled)
              TextButton(
                child: const Text('Location Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openLocationSettings();
                },
              ),
          ],
        );
      },
    );
  }

  /// Listens for real-time updates on the messages table.
  void _listenForLocationUpdates() {
    try {
      // Check if subscription already exists
      _locationSubscription?.cancel();

      final userId = supabase.auth.currentUser!.id;

      _locationSubscription = supabase
          .from('profile')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId)
          .listen(
            (List<Map<String, dynamic>> data) {
              if (data.isNotEmpty) {
                try {
                  final userData = data.first;

                  if (userData["last_loc"] != null) {
                    final newLat = userData["last_loc"]["lat"] as double;
                    final newLong = userData["last_loc"]["long"] as double;
                    final newRange = double.parse(userData["range"].toString());

                    // Check if location or range has changed
                    if (newLat != currentUserLat ||
                        newLong != currentUserLong ||
                        newRange != distanceThreshold) {
                      if (mounted) {
                        setState(() {
                          currentUserLat = newLat;
                          currentUserLong = newLong;
                          distanceThreshold = newRange;
                        });
                      }

                      // Reload messages when location changes
                      _fetchMessages();
                    }
                  }
                } catch (e) {
                  print("Error processing location update: $e");
                }
              }
            },
            onError: (error) {
              print("Error in location updates stream: $error");
              // Try to reconnect if disconnected
              if (_isNetworkAvailable && mounted) {
                Future.delayed(const Duration(seconds: 5), () {
                  _listenForLocationUpdates();
                });
              }
            },
          );
    } catch (e) {
      print("Failed to set up location updates listener: $e");
    }
  }

  /// Listens for real-time updates on the messages table.
  void _listenForUpdates() {
    try {
      // Check if subscription already exists
      _messagesSubscription?.cancel();

      _messagesSubscription =
          supabase.from("messages").stream(primaryKey: ["id"]).listen(
        (data) {
          _fetchMessages();
        },
        onError: (error) {
          print("Error in messages stream: $error");
          // Try to reconnect if disconnected
          if (_isNetworkAvailable && mounted) {
            Future.delayed(const Duration(seconds: 5), () {
              _listenForUpdates();
            });
          }
        },
      );
    } catch (e) {
      print("Failed to set up messages listener: $e");
    }
  }

  void _showRequest(BuildContext context, String recipientUserId) {
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Send Chat Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              content: _isLoading
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Sending chat request...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      'You need to send a request to start a conversation with this user. Would you like to proceed?',
                      style: TextStyle(fontSize: 16),
                    ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              actions: _isLoading
                  ? [] // No actions while loading
                  : [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Outerbutton(text: 'Cancel'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Innerbutton(
                              function: () async {
                                // Update dialog state to show loading
                                setDialogState(() {
                                  _isLoading = true;
                                });

                                try {
                                  // Send chat request
                                  await _sendChatRequest(recipientUserId);

                                  // Close dialog after operation is complete
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                  _fetchMessages();
                                } catch (e) {
                                  setDialogState(() {
                                    _isLoading = false;
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Failed to send request: ${e.toString().split('\n')[0]}"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              text: 'Request',
                            ),
                          ),
                        ],
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendChatRequest(String recipientUserId) async {
    if (!_isNetworkAvailable) {
      throw Exception(
          "No internet connection. Please try again when you're online.");
    }

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

  Widget buildAvatarWithNetworkImage(String url) {
    return CircleAvatar(backgroundImage: NetworkImage(url));
  }

  Widget _buildOfflineWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No internet connection. Some features may be unavailable.',
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
          TextButton(
            onPressed: () {
              _fetchMessages();
            },
            child: Text('Retry'),
          )
        ],
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
            'Infos',
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
          const SizedBox(
            width: 15,
          ),
          // Notifications button
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: IconButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(builder: (builder) => Notifications()),
                )
                    .then((res) {
                  _fetchMessages();
                });
              },
              icon: const Icon(
                Icons.chat,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline status indicator
          if (!_isNetworkAvailable) _buildOfflineWidget(),

          // Location warning if location is disabled
          if (!isLocationEnabled || !_hasLocationPermission)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location services unavailable. Messages may not be accurate.',
                      style: TextStyle(color: Colors.amber.shade800),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Geolocator.openLocationSettings();
                    },
                    child: const Text('Settings'),
                  )
                ],
              ),
            ),

          // Main chat list area
          Expanded(
            child: Stack(
              children: [
                // Chat list.
                Padding(
                  padding:
                      const EdgeInsets.only(top: 15.0, left: 15, bottom: 80),
                  child: Column(
                    children: [
                      Expanded(
                        child: isLoading && chats.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : chats.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 64,
                                          color:Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No messages nearby',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32.0),
                                          child: Text(
                                            'Try adjusting your range or add a new message to start the conversation',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        if (!_isNetworkAvailable ||
                                            !isLocationEnabled)
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                if (!_isNetworkAvailable) {
                                                  // Open system settings for network
                                                  const MethodChannel(
                                                          'app.channel.shared.methodChannel')
                                                      .invokeMethod(
                                                          'openNetworkSettings');
                                                } else if (!isLocationEnabled) {
                                                  Geolocator
                                                      .openLocationSettings();
                                                }
                                              },
                                              child: Text(!_isNetworkAvailable
                                                  ? 'Check Network Settings'
                                                  : 'Check Location Settings'),
                                            ),
                                          ),
                                      ],
                                    ),
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
                                        final bool useImage =
                                            chat['image_link'] != null &&
                                                chat['image_link'] != "";
                                        return Chatcontainer(
                                          type: chat['type'] as String,
                                          avatar: useImage
                                              ? buildAvatarWithNetworkImage(
                                                  chat['image_link'])
                                              : buildAvatar(
                                                  chat['name'] as String),
                                          name: chat['name'] as String,
                                          text: chat['text'] as String,
                                          timestamp: chat["created_at"],
                                          function: () {
                                            if (!_isNetworkAvailable) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "No internet connection. Please try again when connected."),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            if (chat['isActive'] == "pending") {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "You have a pending Request with the user!",
                                                  ),
                                                ),
                                              );
                                            } else if (!isAccept) {
                                              _showRequest(
                                                  context, chat['uid']);
                                            } else {
                                              Navigator.of(context)
                                                  .push(
                                                MaterialPageRoute(
                                                  builder: (builder) =>
                                                      Chatinterface(
                                                    id: chat['uid'] as String,
                                                    avatar: useImage
                                                        ? buildAvatarWithNetworkImage(
                                                            chat['image_link'])
                                                        : buildAvatar(
                                                            chat['name']
                                                                as String,
                                                          ),
                                                    userName:
                                                        chat['name'] as String,
                                                  ),
                                                ),
                                              )
                                                  .then((res) {
                                                _fetchMessages();
                                              });
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
                      if (!_isNetworkAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Cannot send messages while offline."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

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
                              child:
                                  Message(), // Your message composition widget.
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
          ),
        ],
      ),
    );
  }
}
