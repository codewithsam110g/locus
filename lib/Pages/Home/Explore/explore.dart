import 'dart:math';
import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Explore/adminView.dart';
import 'package:locus/Pages/Home/Explore/newGroup.dart';
import 'package:locus/Pages/Home/Explore/userView.dart';
import 'package:locus/widgets/exploreContainer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final supabase = Supabase.instance.client;

  // UI state variables.
  bool isOpen = false;
  bool isAdmin = true;
  bool isAccepted = false;
  bool filter = false;
  bool isSearch = false;
  bool isLoading = true;
  String searchQuery = '';
  List<String> selectedTags = [];
  List<Map<String, dynamic>> exploreList = [];

  // Current user location and distance threshold.
  double currentUserLat = 16.7930;
  double currentUserLong = 80.8225;
  double distanceThreshold = 10000.0; // e.g., 10 kilometers

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setLocation(); // Fetch the user's current location from their profile.
    setupRealtimeListener();
    _fetchData();
    _focusNode.addListener(() {
      setState(() {
        isOpen = _focusNode.hasFocus;
      });
    });
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

  /// Sets up a realtime listener on the 'community' table.
  void setupRealtimeListener() {
    supabase
        .from('community')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      updateExploreList(data);
    });
  }

  /// Fetches all community records.
  Future<void> _fetchData() async {
    // Ensure you retrieve the location field as well.
    final data = await supabase.from('community').select();
    updateExploreList(data);
    setState(() {
      isLoading = false;
    });
  }

  /// Calculates the distance (in meters) between two geographic coordinates
  /// using the Haversine formula.
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
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

  /// Updates the explore list by filtering communities that are accepted,
  /// are not the user's own group, and are within the specified distance.
  void updateExploreList(List<Map<String, dynamic>> data) async {
    final userId = supabase.auth.currentUser!.id;
    final prof = await supabase
        .from("profile")
        .select("com_id")
        .eq("user_id", userId)
        .maybeSingle();

    setState(() {
      bool userIsAdmin =
          data.any((item) => item['com_id'] == prof?['com_id']);
      isAdmin = userIsAdmin;
      isAccepted = data.any((item) =>
          (item['com_id'] == prof?['com_id'] && item['accepted'] == true));

      exploreList = data.where((item) {
        // Only include communities that are accepted and are not the user's own group.
        if (!(item['accepted'] == true  && item['com_id'] != prof?['com_id'] )) {
          return false;
        }
        // Ensure that location information is available.
        if (item['location'] == null) return false;
        final loc = item['location'];

        // Extract latitude.
        final double communityLat = loc['lat'] is num
            ? loc['lat'].toDouble()
            : double.tryParse(loc['lat'].toString()) ?? 0;

        // Extract longitude.
        // Adjust the key name if you store it as 'lng' or 'long' (here, we're using 'long').
        final double communityLong = loc['long'] is num
            ? loc['long'].toDouble()
            : double.tryParse(loc['long'].toString()) ?? 0;

        // Calculate the distance between the user's current location and the community's location.
        final double distance = calculateDistance(
            currentUserLat, currentUserLong, communityLat, communityLong);
        return distance <= distanceThreshold;
      }).map((item) => {
            'id': item['id'].toString(),
            'name': item['title'],
            'description': item['desc'],
            'tag': item['tags'],
            'img': 'assets/img/mohan.jpg', // or use an image from the record if available
            'com_id': item['com_id']
          }).toList();
    });
  }

  /// Further filters the list based on search query and selected tags.
  List<Map<String, dynamic>> getFilteredExploreList() {
    return exploreList.where((item) {
      final matchesSearch =
          item['name'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesTag =
          selectedTags.isEmpty || selectedTags.contains(item['tag']);
      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          isOpen = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: isSearch
              ? TextField(
                  focusNode: _focusNode,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.only(left: 20.0),
                  child: Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Electrolize',
                    ),
                  ),
                ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.only(
                    left: 20, right: 20, bottom: isOpen ? 0 : 80),
                child: Column(
                  children: [
                    if (isAdmin && !isSearch)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: GestureDetector(
                          onTap: (isAdmin && isAccepted)
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (builder) =>
                                            const Adminview()),
                                  )
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: isAdmin
                                  ? (isAccepted
                                      ? Theme.of(context)
                                          .colorScheme
                                          .secondary
                                      : Colors.orange.shade700)
                                  : Colors.grey,
                            ),
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAdmin
                                      ? (isAccepted
                                          ? 'Your Group'
                                          : 'Your Group is not accepted yet')
                                      : 'Not an Admin',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 15),
                                ),
                                if (isAccepted)
                                  const Icon(Icons.arrow_forward,
                                      color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: getFilteredExploreList().length,
                        itemBuilder: (context, index) {
                          final list = getFilteredExploreList()[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return Userview(id: list['com_id']);
                              }));
                            },
                            child: Explorecontainer(
                              name: list['name'],
                              description: list['description'],
                              img: list['img'],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80, right: 20),
          child: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Newgroup(),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
