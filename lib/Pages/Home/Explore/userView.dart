import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Explore/infoScreen.dart';
import 'package:locus/widgets/chat_bubble_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Userview extends StatefulWidget {
  final String id;
  final String name;
  final String profilePicUrl;
  const Userview({
    super.key,
    required this.id,
    required this.name,
    required this.profilePicUrl,
  });

  @override
  State<Userview> createState() => _UserviewState();
}

class _UserviewState extends State<Userview> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  Map<String, dynamic>? communityInfo; // Store community info

  final supabase = Supabase.instance.client;
  late String imgURL;

  @override
  void initState() {
    super.initState();
    imgURL = widget.profilePicUrl;
    setupListener();
    fetchCommunityInfo();
  }

  Future<void> fetchCommunityInfo() async {
    try {
      final response = await supabase
          .from('community')
          .select('*')
          .eq('com_id', widget.id)
          .single();

      if (mounted) {
        setState(() {
          communityInfo = response;
          imgURL = response['logo_link'] != null
              ? response['logo_link'] as String
              : widget.profilePicUrl;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching community info: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> setupListener() async {
    // Listen for changes to the community_messages table for this specific community
    supabase
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .eq('com_id', widget.id)
        .order('created_at', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              messages = data;
            });
          }
        });

    // Listen for changes to the community table to update the logo
    supabase
        .from('community')
        .stream(primaryKey: ['com_id'])
        .eq('com_id', widget.id)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              imgURL = data[0]['logo_link'] as String? ?? widget.profilePicUrl;
              isLoading = false;
            });
          }
        });
  }

  String formatDateTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    int hour = dateTime.hour;
    String period = hour >= 12 ? "PM" : "AM";
    
    // Convert to 12-hour format
    hour = hour > 12 ? hour - 12 : hour;
    hour = hour == 0 ? 12 : hour; // Handle midnight (0:00) as 12 AM
    
    return "${hour.toString()}:${dateTime.minute.toString().padLeft(2, '0')} $period";
  }

  String getDateHeader(String timestamp) {
    DateTime messageDate = DateTime.parse(timestamp).toLocal();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) {
      return "Today";
    } else if (messageDay == yesterday) {
      return "Yesterday";
    } else if (now.difference(messageDate).inDays < 7) {
      // Within the last week
      return DateFormat('EEEE').format(messageDate); // Day name (e.g., "Monday")
    } else {
      // More than a week ago
      return DateFormat('MMM d, yyyy').format(messageDate); // e.g., "Mar 23, 2025"
    }
  }

  void _showBottomSheet() {
    if (communityInfo == null) {
      // Show loading or error message if community info is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community information not available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Infoscreen(communityData: communityInfo!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        title: Row(
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
            GestureDetector(
              onTap: () {
                _showBottomSheet();
              },
              child: CircleAvatar(
                backgroundImage: imgURL.contains("asset")
                    ? AssetImage(imgURL) as ImageProvider
                    : NetworkImage(imgURL) as ImageProvider,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                _showBottomSheet();
              },
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Electrolize',
                ),
              ),
            ),
          ],
        ),
        actions: [],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? const Center(
                            child: Text(
                              "No messages yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 20),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              
                              // Show date header for first message or when date changes
                              bool showDateHeader = false;
                              String dateHeader = getDateHeader(message["created_at"]);
                              
                              if (index == 0) {
                                showDateHeader = true;
                              } else {
                                String prevDateHeader = getDateHeader(messages[index - 1]["created_at"]);
                                showDateHeader = dateHeader != prevDateHeader;
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showDateHeader)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16, 
                                            vertical: 5
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondary,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            dateHeader,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ChatBubbleUser(
                                    message: message["message"],
                                    time: formatDateTime(message["created_at"]),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      "Messages are only sent by Comunity Admin.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}