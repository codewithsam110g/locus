import 'package:flutter/material.dart';
import 'package:locus/widgets/chat_bubble_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Userview extends StatefulWidget {
  final String id;
  final String name;
  const Userview({
    super.key,
    required this.id,
    required this.name,
  });

  @override
  State<Userview> createState() => _UserviewState();
}

class _UserviewState extends State<Userview> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  final supabase = Supabase.instance.client;
  String imgURL = 'assets/img/mohan.jpg';

  @override
  void initState() {
    super.initState();
    setupListener();
  }

  Future<void> setupListener() async {
    // Listen for changes to the community_messages table for this specific community
    supabase
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .eq('com_id', widget.id)
        .order('created_at',ascending:true)
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
          imgURL = data[0]['logo_link'] as String;
          isLoading = false;
        });
      }
    });
  }

  String formatDateTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} "
        "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: imgURL.contains("asset")
                  ? AssetImage(imgURL)
                  : NetworkImage(imgURL),
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: 'Electrolize',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
                              return ChatBubbleUser(
                                message: message["message"],
                                time: formatDateTime(message["created_at"]),
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
