import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/Pages/Home/Chat/chatRequested.dart';
import 'package:locus/widgets/primaryWidget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:timeago/timeago.dart' as timeago;

class Notifications extends StatefulWidget {
  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, String>> filteredChats = [];
  List<Map<String, String>> chatRequests = [];
  List<Map<String, String>> activeChats = [];

  final supabase = Supabase.instance.client;

  // Stream subscriptions to manage realtime listeners
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      _filterChats(_searchController.text);
    });

    // Fetch initial data
    _fetchChatRequests();
    _fetchChats();

    // Setup realtime listeners
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Listen for changes in the requests table
    final requestsSubscription =
        supabase.from('requests').stream(primaryKey: ['id']).listen((data) {
      _fetchChatRequests();
    });

    // Listen for changes in the chats table
    final chatsSubscription =
        supabase.from('chats').stream(primaryKey: ['id']).listen((data) {
      _fetchChats();
    });

    // Listen for changes in the profile table (for name and image updates)
    final profileSubscription =
        supabase.from('profile').stream(primaryKey: ['user_id']).listen((data) {
      // Refresh both chats and requests to update names and images
      _fetchChats();
      _fetchChatRequests();
    });

    // Store subscriptions for cleanup
    _subscriptions
        .addAll([requestsSubscription, chatsSubscription, profileSubscription]);
  }

  Future<void> _fetchChats() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final response = await supabase
        .from('chats')
        .select()
        .or('uid_1.eq.$currentUserId,uid_2.eq.$currentUserId')
        .eq('is_active', true);

    if (response.isEmpty) {
      setState(() {
        activeChats = [];
      });
      return;
    }

    Set<String> userIdsToFetch = {};
    for (var chat in response) {
      String otherUserId =
          chat['uid_1'] == currentUserId ? chat['uid_2'] : chat['uid_1'];

      if (otherUserId.isNotEmpty) {
        userIdsToFetch.add(otherUserId);
      }
    }

    // We'll store both names and image links
    Map<String, Map<String, String>> userInfo = {};
    if (userIdsToFetch.isNotEmpty) {
      final profilesResponse = await supabase
          .from('profile')
          .select('user_id, name, image_link')
          .or(userIdsToFetch.map((id) => 'user_id.eq.$id').join(','));

      for (var profile in profilesResponse) {
        userInfo[profile['user_id']] = {
          'name': profile['name'] ?? 'Unknown User',
          'image_link': profile['image_link'] ?? '',
        };
      }
    }

    setState(() {
      activeChats = response.map<Map<String, String>>((chat) {
        String otherUserId =
            chat['uid_1'] == currentUserId ? chat['uid_2'] : chat['uid_1'];

        var userProfileInfo = userInfo[otherUserId] ??
            {'name': 'Unknown User', 'image_link': ''};

        return {
          'id': otherUserId,
          'chat_id': chat['id'].toString(),
          'name': userProfileInfo['name'] ?? 'Unknown User',
          'img': userProfileInfo['image_link']?.isNotEmpty == true
              ? userProfileInfo['image_link']!
              : 'assets/img/mohan.jpg', // Default image if image_link is empty
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    // Clean up all stream subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  Future<void> _fetchChatRequests() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Fetch chat requests where the current user is involved
    final response = await supabase
        .from('requests')
        .select()
        .or('reciever_uid.eq.$currentUserId,requested_uid.eq.$currentUserId')
        .or('status.eq.pending,status.eq.terminated');

    if (response.isEmpty) {
      setState(() {
        chatRequests = [];
        if (_searchController.text.isNotEmpty) {
          _filterChats(_searchController.text);
        }
      });
      return;
    }

    // Extract unique user IDs to fetch names and images
    Set<String> userIdsToFetch = {};
    for (var req in response) {
      String otherUserId = req['reciever_uid'] == currentUserId
          ? req['requested_uid']
          : req['reciever_uid'];

      if (otherUserId != null && otherUserId.isNotEmpty) {
        userIdsToFetch.add(otherUserId);
      }
    }

    // Fetch user names and images from the profile table
    Map<String, Map<String, String>> userInfo = {};
    if (userIdsToFetch.isNotEmpty) {
      final profilesResponse = await supabase
          .from('profile')
          .select('user_id, name, image_link')
          .or(userIdsToFetch.map((id) => 'user_id.eq.$id').join(','));

      for (var profile in profilesResponse) {
        userInfo[profile['user_id']] = {
          'name': profile['name'] ?? 'Unknown User',
          'image_link': profile['image_link'] ?? '',
        };
      }
    }

    // Construct the chatRequests list with names and images
    if (mounted) {
      setState(() {
        chatRequests = response.map<Map<String, String>>((req) {
          String otherUserId = req['reciever_uid'] == currentUserId
              ? req['requested_uid']
              : req['reciever_uid'];

          var userProfileInfo = userInfo[otherUserId] ??
              {'name': 'Unknown User', 'image_link': ''};

          return {
            'id': otherUserId,
            'request_id': req['id'].toString(),
            'name': userProfileInfo['name'] ?? 'Unknown User',
            'lmsg': req['status'] ?? '',
            'img': userProfileInfo['image_link']?.isNotEmpty == true
                ? userProfileInfo['image_link']!
                : 'assets/img/mohan.jpg', // Default image if image_link is empty
            'type':
                req['reciever_uid'] == currentUserId ? 'incoming' : 'outgoing',
          };
        }).toList();

        // Update filtered chats if search is active
        if (_searchController.text.isNotEmpty) {
          _filterChats(_searchController.text);
        }
      });
    }
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredChats = [...activeChats, ...chatRequests];
      } else {
        filteredChats = [...activeChats, ...chatRequests]
            .where((chat) =>
                chat['name']!.toLowerCase().contains(query.toLowerCase()) ||
                chat['lmsg']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Electrolize',
                    ),
                  ),
                ],
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isSearching ? _stopSearch : _startSearch,
                  child: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: (!_isSearching && _tabController != null)
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Chats'),
                  Tab(text: 'Requests'),
                ],
              )
            : null,
      ),
      body: _isSearching
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(),
                _buildRequestList(),
              ],
            ),
    );
  }

  Widget _buildChatList() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: activeChats.isNotEmpty
          ? ListView.builder(
              itemCount: activeChats.length,
              itemBuilder: (context, index) {
                final chat = activeChats[index];
                final chatId = chat['chat_id'];
                final imageUrl = chat['img']!;
                final isAssetImage = imageUrl.startsWith('assets/');
  
                return StatefulBuilder(
                  builder: (context, setState) {
                    Timer? timer;
  
                    void startTimer(DateTime messageTime) {
                      Duration updateInterval = _getUpdateInterval(messageTime);
  
                      timer?.cancel(); // Cancel any existing timer
  
                      timer = Timer.periodic(updateInterval, (timer) {
                        setState(() {}); // Trigger UI update
                      });
                    }
  
                    return FutureBuilder(
                      future: supabase
                          .from('private_messages')
                          .select('message, created_at, hidden_by')
                          .eq('chat_id', chatId as Object)
                          .order('created_at', ascending: false)
                          .limit(20), // Fetch more messages to find non-hidden ones
                      builder: (context, snapshot) {
                        String lastMessage = "Tap to chat";
                        String lastMessageTime = "";
  
                        if (snapshot.hasData && snapshot.data != null) {
                          // Get current user's ID
                          final currentUserId = supabase.auth.currentUser?.id;
                          
                          // Find the first message not hidden by current user
                          final messages = snapshot.data as List;
                          
                          // Using a manual loop instead of firstWhere to avoid orElse type issues
                          Map<String, dynamic>? visibleMessage;
                          for (var msg in messages) {
                            final hiddenBy = (msg['hidden_by'] as List?) ?? [];
                            if (!hiddenBy.contains(currentUserId)) {
                              visibleMessage = msg;
                              break;
                            }
                          }
  
                          if (visibleMessage != null) {
                            lastMessage = visibleMessage['message'] ?? "Tap to chat";
                            if (lastMessage.length > 15) {
                              lastMessage = lastMessage.substring(0, 10) + "...";
                            }
  
                            if (visibleMessage['created_at'] != null) {
                              DateTime messageTime =
                                  DateTime.parse(visibleMessage['created_at'])
                                      .toLocal();
                              lastMessageTime = timeago.format(messageTime);
  
                              startTimer(messageTime); // Start auto-updates
                            }
                          }
                        }
  
                        return Primarywidget(
                          img: imageUrl,
                          name: chat['name']!,
                          lmsg: lastMessage,
                          time: lastMessageTime,
                          function: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (builder) => Chatinterface(
                                  id: chat['id']!,
                                  avatar: isAssetImage
                                      ? Image.asset(imageUrl)
                                      : Image.network(
                                          imageUrl,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset('assets/img/mohan.jpg');
                                          },
                                        ),
                                  userName: chat['name']!,
                                ),
                              ),
                            );
  
                            _fetchChats();
                          },
                        );
                      },
                    );
                  },
                );
              },
            )
          : const Center(
              child: Text(
                "No Active Chats",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
            ),
    );
  }

  /// Determines the update interval based on the message age
  Duration _getUpdateInterval(DateTime messageTime) {
    final Duration elapsed = DateTime.now().difference(messageTime);

    if (elapsed.inMinutes < 10) {
      return const Duration(minutes: 1);
    } else if (elapsed.inMinutes < 60) {
      return const Duration(minutes: 5);
    } else if (elapsed.inHours < 24) {
      return const Duration(hours: 1);
    } else {
      return const Duration(days: 1);
    }
  }

  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: filteredChats.isNotEmpty
          ? ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                final imageUrl = chat['img']!;
                final isAssetImage = imageUrl.startsWith('assets/');

                return Primarywidget(
                  img: imageUrl,
                  name: chat['name']!,
                  lmsg: chat['lmsg'] ?? 'Tap to chat',
                  time: '',
                  function: () {
                    if (chat.containsKey('chat_id')) {
                      // It's an active chat
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (builder) => Chatinterface(
                            id: chat['id']!,
                            avatar: isAssetImage
                                ? Image.asset(imageUrl)
                                : Image.network(
                                    imageUrl,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset('assets/img/mohan.jpg');
                                    },
                                  ),
                            userName: chat['name']!,
                          ),
                        ),
                      );
                    } else {
                      // It's a chat request
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (builder) => Chatforrequested(
                            id: chat['id']!,
                            img: imageUrl,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            )
          : const Center(
              child: Text(
                "No Results Found",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildRequestList() {
    final incomingRequests =
        chatRequests.where((chat) => chat['type'] == 'incoming').toList();
    final outgoingRequests =
        chatRequests.where((chat) => chat['type'] == 'outgoing').toList();

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **Incoming Requests**
            if (incomingRequests.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Incoming Requests",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: incomingRequests.length,
                    itemBuilder: (context, index) {
                      final chat = incomingRequests[index];
                      final imageUrl = chat['img']!;
                      final isAssetImage = imageUrl.startsWith('assets/');

                      return Primarywidget(
                        img: imageUrl,
                        name: chat['name']!,
                        lmsg: "Status: ${chat['lmsg']}",
                        time: '',
                        function: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (builder) => Chatforrequested(
                                id: chat['id']!,
                                img: imageUrl,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              )
            else if (outgoingRequests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "No Incoming Requests",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // **Outgoing Requests**
            if (outgoingRequests.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Requests",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: outgoingRequests.length,
                    itemBuilder: (context, index) {
                      final chat = outgoingRequests[index];
                      final imageUrl = chat['img']!;

                      return Primarywidget(
                        img: imageUrl,
                        name: chat['name']!,
                        lmsg: "Status: ${chat['lmsg']}",
                        time: '',
                        function: () {}, // Add functionality if needed
                      );
                    },
                  ),
                ],
              )
            else if (incomingRequests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "No Outgoing Requests",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
