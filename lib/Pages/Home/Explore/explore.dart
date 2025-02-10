import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Explore/adminView.dart';
import 'package:locus/Pages/Home/Explore/newGroup.dart';
import 'package:locus/Pages/Home/Explore/userView.dart';
import 'package:locus/widgets/exploreContainer.dart';

class Explore extends StatefulWidget {
  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  late bool isOpen = false;
  late bool isAdmin = true;
  final exploreList = [
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Mohan Veera',
      'description':
          'Mohan Bala Nagendra Veera Mohan Nagendra Veera ..... hcbhbhb zjxu Abg',
      'tag': 'Organization',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Mohan Veera 2',
      'description': 'Another description for Mohan 2 ..... hcbhbhb zjxu Abg',
      'tag': 'local',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Mohan Veera 3',
      'description':
          'Mohan Bala Nagendra Veera Mohan Nagendra Veera ..... hcbhbhb zjxu Abg',
      'tag': 'Organization',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'John Doe',
      'description':
          'John is an expert in Flutter development and enjoys coding in Dart.',
      'tag': 'local',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Jane Smith',
      'description':
          'Jane runs a local art organization that promotes community engagement.',
      'tag': 'Organization',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Alice Johnson',
      'description':
          'Alice is a local entrepreneur who started her business from scratch.',
      'tag': 'local',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Bob Brown',
      'description':
          'Bob is the president of a non-profit organization focused on education.',
      'tag': 'Organization',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Charlie Green',
      'description':
          'Charlie is known for his local gardening workshops and community events.',
      'tag': 'local',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Diana Prince',
      'description':
          'Diana leads an organization that advocates for wildlife conservation.',
      'tag': 'Organization',
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Ethan Hunt',
      'description':
          'Ethan is a local athlete who participates in community sports events.',
      'tag': 'local',
    },
  ];

  bool filter = false;
  String searchQuery = '';
  List<String> selectedTags = [];
  final FocusNode _focusNode = FocusNode();
  bool isSearch = false;

  // Function to filter explore list based on tags and search query
  List<Map<String, String>> getFilteredExploreList() {
    return exploreList.where((item) {
      final matchesSearch =
          item['name']!.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesTag =
          selectedTags.isEmpty || selectedTags.contains(item['tag']);
      return matchesSearch && matchesTag;
    }).toList();
  }

  // Function to toggle tag selection
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
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isOpen = _focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Close keyboard
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
                      searchQuery = value; // Update search query
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isSearch = !isSearch; // Toggle search mode
                    if (!isSearch) {
                      searchQuery =
                          ''; // Clear search query when closing search
                    }
                  });
                },
                child: Icon(
                  isSearch ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding:
                  EdgeInsets.only(left: 20, right: 20, bottom: isOpen ? 0 : 80),
              child: Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  if (isAdmin && !isSearch)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (builder) => Adminview(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Group',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                              Icon(
                                size: 18,
                                Icons.arrow_forward_ios,
                                color: Colors.black,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (isAdmin && !isSearch)
                    SizedBox(
                      height: 20,
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: getFilteredExploreList().length,
                      itemBuilder: (context, index) {
                        final list = getFilteredExploreList()[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (builder) => Userview(
                                  name: list['name'] as String,
                                  img: list['img'] as String,
                                ),
                              ),
                            );
                          },
                          child: Explorecontainer(
                            name: list['name'] as String,
                            description: list['description'] as String,
                            img: list['img'] as String,
                          ),
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
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child:
                              Newgroup(), // Display your Newgroup widget here
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
                  padding: EdgeInsets.all(8),
                  child: Icon(
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
    );
  }
}
