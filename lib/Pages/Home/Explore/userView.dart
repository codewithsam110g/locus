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

  @override
  void initState() {
    super.initState();
  }

  

  Future<void> fetchMessages() async {
    final fetchedMessages = await supabase
        .from("community_messages")
        .select("message, created_at")
        .eq("com_id", widget.id)
        .order("created_at", ascending: true);

    setState(() {
      messages = fetchedMessages;
      isLoading = false;
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
            const CircleAvatar(
              backgroundImage: AssetImage("assets/img/mohan.jpg"),
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
                      "Messaging is disabled in this chat.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
