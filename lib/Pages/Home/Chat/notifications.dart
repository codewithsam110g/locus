import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/Pages/Home/Chat/chatRequested.dart';
import 'package:locus/widgets/primaryWidget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      _filterChats(_searchController.text);
    });

    // Fetch requests from Supabase
    _fetchChatRequests();
    _fetchChats();
  }
  
  Future<void> _fetchChats() async {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;
  
      final response = await supabase
          .from('chats')
          .select()
          .or('uid_1.eq.$currentUserId,uid_2.eq.$currentUserId')
          .eq('is_active', true);
  
      if (response.isEmpty) return;
  
      Set<String> userIdsToFetch = {};
      for (var chat in response) {
        String otherUserId =
            chat['uid_1'] == currentUserId ? chat['uid_2'] : chat['uid_1'];
  
        if (otherUserId.isNotEmpty) {
          userIdsToFetch.add(otherUserId);
        }
      }
  
      Map<String, String> userNames = {};
      if (userIdsToFetch.isNotEmpty) {
        final profilesResponse = await supabase
            .from('profile')
            .select('user_id, name')
            .or(userIdsToFetch.map((id) => 'user_id.eq.$id').join(','));
  
        for (var profile in profilesResponse) {
          userNames[profile['user_id']] = profile['name'] ?? 'Unknown User';
        }
      }
  
      setState(() {
        activeChats = response.map<Map<String, String>>((chat) {
          String otherUserId =
              chat['uid_1'] == currentUserId ? chat['uid_2'] : chat['uid_1'];
  
          return {
            'id': otherUserId,
            'name': userNames[otherUserId] ?? 'Unknown User',
            'img': 'assets/img/mohan.jpg', // Replace with real profile image
          };
        }).toList();
      });
    }
    
  

  @override
  void dispose() {
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

    if (response.isEmpty) return;

    // Extract unique user IDs to fetch names
    Set<String> userIdsToFetch = {};
    for (var req in response) {
      String otherUserId = req['reciever_uid'] == currentUserId
          ? req['requested_uid']
          : req['reciever_uid'];

      if (otherUserId != null && otherUserId.isNotEmpty) {
        userIdsToFetch.add(otherUserId);
      }
    }

    // Fetch user names from the profile table
    Map<String, String> userNames = {};
    if (userIdsToFetch.isNotEmpty) {
      final profilesResponse = await supabase
          .from('profile')
          .select('user_id, name')
          .or(userIdsToFetch.map((id) => 'user_id.eq.$id').join(','));
      for (var profile in profilesResponse) {
        userNames[profile['user_id']] = profile['name'] ?? 'Unknown User';
      }
    }

    // Construct the chatRequests list with names
    setState(() {
      chatRequests = response.map<Map<String, String>>((req) {
        String otherUserId = req['reciever_uid'] == currentUserId
            ? req['requested_uid']
            : req['reciever_uid'];

        return {
          'id': otherUserId,
          'name': userNames[otherUserId] ??
              'Unknown User', // Retrieved  from profile table
          'lmsg': req['status'] ?? '',
          'img':
              'assets/img/mohan.jpg', // Default image, replace with actual user image
          'type':
              req['reciever_uid'] == currentUserId ? 'incoming' : 'outgoing',
        };
      }).toList();
    });
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredChats = List.from(chatRequests);
      } else {
        filteredChats = chatRequests
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
            : const Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text(
                  'Messages',
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
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isSearching ? _stopSearch : _startSearch,
                  child: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                ),
                if (!_isSearching) const SizedBox(width: 20),
                if (!_isSearching)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(
                      Icons.close,
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
                _buildRequestList(), // Updated request list
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
                  return Primarywidget(
                    img: chat['img']!,
                    name: chat['name']!,
                    lmsg: 'Tap to chat',
                    function: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (builder) => Chatinterface(
                            id: chat['id']!,
                            avatar: Image.asset(chat['img']!),
                          ),
                        ),
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

  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: filteredChats.isNotEmpty
          ? ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                return Primarywidget(
                  img: chat['img']!,
                  name: chat['name']!,
                  lmsg: chat['lmsg']!,
                  function: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (builder) => Chatinterface(
                          id: chat['id']!,
                          avatar: Image.asset(chat['img']!),
                        ),
                      ),
                    );
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
                    return Primarywidget(
                      img: chat['img']!,
                      name: chat['name']!,
                      lmsg: "Status: ${chat['lmsg']}",
                      function: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (builder) => Chatforrequested(
                              id: chat['id']!,
                              img: chat['img']!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            )
          else
            const Center(
              child: Text(
                "No Incoming Requests",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
            ),

          const SizedBox(height: 20), // Spacing

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
                    return Primarywidget(
                      img: chat['img']!,
                      name: chat['name']!,
                      lmsg: "Status: ${chat['lmsg']}",
                      function: () {}, // Add functionality if needed
                    );
                  },
                ),
              ],
            )
          else
            const Center(
              child: Text(
                "No Outgoing Requests",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
