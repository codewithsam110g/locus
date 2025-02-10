import 'package:flutter/material.dart';
import 'package:locus/widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Adminview extends StatefulWidget {
  const Adminview({super.key});

  @override
  _AdminviewState createState() => _AdminviewState();
}

class _AdminviewState extends State<Adminview> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  final supabase = Supabase.instance.client;

  String groupName = "Group Name";
  String com_id = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCommunityInfo();
  }

  Future<void> fetchCommunityInfo() async {
    final userId = supabase.auth.currentUser!.id;
    final comData = await supabase
        .from("profile")
        .select("com_id, community(*)")
        .eq("user_id", userId)
        .single();

    setState(() {
      com_id = comData['com_id'];
      groupName = comData['community']['title'];
    });

    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final fetchedMessages = await supabase
        .from("community_messages")
        .select("message, created_at")
        .eq("com_id", com_id)
        .order("created_at", ascending: true);

    setState(() {
      messages = fetchedMessages;
      isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    _messageController.clear();

    await supabase.from("community_messages").insert({
      "com_id": com_id,
      "message": messageText,
      "created_at": DateTime.now().toUtc().toIso8601String(),
    });

    fetchMessages();
  }

  String formatDateTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} "
        "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/img/mohan.jpg'),
            ),
            const SizedBox(width: 10),
            Text(
              groupName,
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
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No messages yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return ChatBubble(
                            message: message["message"],
                            time: formatDateTime(message["created_at"]),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 28, color: Colors.white),
                    onPressed: sendMessage,
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(),
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