import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/Pages/Home/Chat/chatRequested.dart';
import 'package:locus/widgets/primaryWidget.dart';

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

  final List<Map<String, String>> chatLists = [
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Mohan',
      'lmsg': 'Hello',
      'id': 'mohan123',
      'type': 'chats'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Nagendra',
      'lmsg': 'Hey!',
      'id': 'nagendra123',
      'type': 'chats'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Bala',
      'lmsg': 'Good Morning',
      'id': 'bala123',
      'type': 'request'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Veera',
      'lmsg': 'How are you?',
      'id': 'veera123',
      'type': 'chats'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Venkatesh',
      'lmsg': 'Need help?',
      'id': 'venkatesh123',
      'type': 'request'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Ponnuru',
      'lmsg': 'Sure!',
      'id': 'ponnuru123',
      'type': 'request'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Venkat',
      'lmsg': 'Call me',
      'id': 'venkat123',
      'type': 'chats'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      _filterChats(_searchController.text);
    });
    filteredChats = List.from(chatLists); // Initially display all chats
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
      _searchController.clear();
      filteredChats = List.from(chatLists); // Reset list
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      filteredChats = List.from(chatLists); // Reset list
    });
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredChats = List.from(chatLists);
      } else {
        filteredChats = chatLists
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
            : Padding(
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
              padding: EdgeInsets.only(right: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isSearching ? _stopSearch : _startSearch,
                    child: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                  ),
                  if (!_isSearching)
                    SizedBox(
                      width: 20,
                    ),
                  if (!_isSearching)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                ],
              )),
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
                _buildChatList("chats"),
                _buildChatList("request"),
              ],
            ),
    );
  }

  Widget _buildChatList(String type) {
    final filteredList =
        chatLists.where((chat) => chat['type'] == type).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: filteredList.isNotEmpty
          ? ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final chat = filteredList[index];
                final isRequest = chat['type'] == 'request';
                return Primarywidget(
                  img: chat['img']!,
                  name: chat['name']!,
                  lmsg: chat['lmsg']!,
                  function: () {
                    if (!isRequest) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (builder) => Chatinterface(
                            name: chat['name']!,
                            img: chat['img']!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (builder) => Chatforrequested(
                            name: chat['name']!,
                            img: chat['img']!,
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
                "No Chats Available",
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
                          name: chat['name']!,
                          img: chat['img']!,
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
}
