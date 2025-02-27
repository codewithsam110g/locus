import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting timestamps
import 'package:locus/widgets/chat_bubble_user.dart';
import 'package:locus/widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Chatinterface extends StatefulWidget {
  final String id;
  final Widget avatar;

  const Chatinterface({
    super.key,
    required this.id,
    required this.avatar,
  });

  @override
  State<Chatinterface> createState() => _ChatinterfaceState();
}

class _ChatinterfaceState extends State<Chatinterface> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  List<Map<String, dynamic>> messages = []; // Combined messages list
  String? userName;
  int chatId = -1;
  bool isLoading = true;
  final supabase = Supabase.instance.client;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        isTyping = _controller.text.isNotEmpty;
      });
    });
    fetchUserName();
  }

  @override
  void dispose() {
    // Cancel the stream subscription when the widget is disposed
    _messagesSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchUserName() async {
    try {
      final response = await supabase
          .from('profile')
          .select('name')
          .eq('user_id', widget.id)
          .single();

      if (response != null && response['name'] != null) {
        setState(() {
          userName = response['name'];
        });
      }
    } catch (error) {
      print('Error fetching user name: $error');
    }

    try {
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception("No authenticated user found.");
      }

      final chatResponse = await supabase
          .from('chats')
          .select('id')
          .or('and(uid_1.eq.$currentUserId,uid_2.eq.${widget.id}),and(uid_1.eq.${widget.id},uid_2.eq.$currentUserId))')
          .maybeSingle();

      if (chatResponse != null && chatResponse['id'] != null) {
        setState(() {
          chatId = chatResponse['id'];
        });
        await fetchMessages();
        _subscribeToMessages();
      } else {
        print("Chat not found between users.");
      }
    } catch (error) {
      print('Error fetching chat ID: $error');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _subscribeToMessages() {
    if (chatId == -1) return;

    // Use the stream method to listen for real-time updates
    _messagesSubscription = supabase
        .from('private_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .listen((data) {
          // When new data arrives, refresh messages
          fetchMessages();
        });
  }

  Future<void> fetchMessages() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception("No authenticated user found.");
      }

      final data = await supabase
          .from("private_messages")
          .select("message, sent_by, created_at")
          .eq("chat_id", chatId)
          .order("created_at", ascending: true);

      if (data != null) {
        List<Map<String, dynamic>> allMessages = [];

        for (var message in data) {
          final formattedTime = formatTimestamp(message['created_at']);
          final isCurrentUser = message['sent_by'] == currentUserId;

          allMessages.add({
            "message": message['message'],
            "time": formattedTime,
            "isCurrentUser": isCurrentUser,
            "timestamp":
                message['created_at'], // Keep original timestamp for sorting
          });
        }

        setState(() {
          messages = allMessages;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (error) {
      print("Error fetching messages: $error");
    }
  }

  Future<void> sendMessage() async {
    if (_controller.text.isEmpty || chatId == -1) return;

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      print("No authenticated user found.");
      return;
    }

    final messageText = _controller.text.trim();
    final timestamp = DateTime.now().toUtc().toIso8601String();

    try {
      await supabase.from("private_messages").insert({
        "chat_id": chatId,
        "message": messageText,
        "sent_by": currentUserId,
        "created_at": timestamp,
      });

      // Clear the text field
      _controller.clear();

      // No need to manually update messages as the stream will trigger fetchMessages()
    } catch (error) {
      print("Error sending message: $error");
    }
  }

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('hh:mm a').format(dateTime); // Format to 12-hour time
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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: widget.avatar,
              ),
            ),
            const SizedBox(width: 10),
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    userName ?? "Unknown User",
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  if (message['isCurrentUser']) {
                    return ChatBubble(
                      message: message['message'],
                      time: message['time'],
                    );
                  } else {
                    return ChatBubbleUser(
                      message: message['message'],
                      time: message['time'],
                    );
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
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
