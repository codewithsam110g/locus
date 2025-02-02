import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Explore/newGroup.dart';
import 'package:locus/widgets/exploreContainer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Explore extends StatefulWidget {
  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final supabase = Supabase.instance.client;
  bool filter = false;
  String searchQuery = '';
  List<String> selectedTags = [];
  List<Map<String, dynamic>> exploreList = [];

  @override
  void initState() {
    super.initState();
    fetchCommunities();
    setupRealtimeListener();
  }

  Future<void> fetchCommunities() async {
    final response = await supabase.from('community').select('*').eq('accepted', true);
    setState(() {
      exploreList = response.map((item) => {
        'name': item['title'],
        'description': item['desc'],
        'tag': item['tags'],
        'img': 'assets/img/mohan.jpg',
      }).toList();
    });
  }

  void setupRealtimeListener() {
    supabase.from('community').stream(primaryKey: ['id']).eq('accepted', true).listen((data) {
      setState(() {
        exploreList = data.map((item) => {
          'name': item['title'],
          'description': item['desc'],
          'tag': item['tags'],
          'img': 'assets/img/mohan.jpg',
        }).toList();
      });
    });
  }

  List<Map<String, dynamic>> getFilteredExploreList() {
    return exploreList.where((item) {
      final matchesSearch = item['name'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesTag = selectedTags.isEmpty || selectedTags.contains(item['tag']);
      return matchesSearch && matchesTag;
    }).toList();
  }

  void toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20, bottom: 100),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 60.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.filter_list),
                        onPressed: () => setState(() => filter = !filter),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                if (filter)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text('Organization'),
                          selected: selectedTags.contains('Organization'),
                          onSelected: (selected) => toggleTag('Organization'),
                        ),
                        SizedBox(width: 10),
                        FilterChip(
                          label: Text('Local'),
                          selected: selectedTags.contains('local'),
                          onSelected: (selected) => toggleTag('local'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: getFilteredExploreList().length,
                    itemBuilder: (context, index) {
                      final list = getFilteredExploreList()[index];
                      return Explorecontainer(
                        name: list['name'],
                        description: list['description'],
                        img: list['img'],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
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
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Newgroup(),
                      );
                    },
                  ),
                );
              },
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
