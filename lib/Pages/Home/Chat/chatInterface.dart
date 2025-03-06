import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting timestamps
import 'package:locus/widgets/chat_bubble_user.dart';
import 'package:locus/widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Chatinterface extends StatefulWidget {
  final String id;
  final Widget avatar;
  final String? userName;

  const Chatinterface({
    super.key,
    required this.id,
    required this.avatar,
    this.userName,
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
  bool isFetchMessages = false;

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
    setState(() {
      isFetchMessages = true;
    });
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
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (error) {
      print("Error fetching messages: $error");
    } finally {
      setState(() {
        isFetchMessages = false;
      });
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

  String getMessageDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return "Today";
    } else if (messageDate == yesterday) {
      return "Yesterday";
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 6)))) {
      return DateFormat('EEEE').format(dateTime); // Example: "Monday"
    } else {
      return DateFormat('dd MMM yyyy')
          .format(dateTime); // Example: "01 Mar 2025"
    }
  }

  Future<void> _clearChat() async {
    try {
      await supabase.from("private_messages").delete().eq("chat_id", chatId);

      setState(() {
        messages.clear(); // Clear messages list in UI
      });

      print("Chat cleared successfully");
    } catch (error) {
      print("Error clearing chat: $error");
    }
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Clear chat?",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("This will remove all messages in this chat."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _clearChat();
                Navigator.pop(context);
              },
              child: Text(
                "Clear Chat",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeclineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Decline this chat?",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "You won’t receive messages from this user anymore.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Implement decline chat logic here
                print("Chat declined");
                Navigator.pop(context);
              },
              child: Text(
                "Decline",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
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
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: widget.avatar,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.userName ?? "Unknown User",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Electrolize',
                ),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  final RenderBox button =
                      context.findRenderObject() as RenderBox;
                  final RenderBox overlay = Overlay.of(context)
                      .context
                      .findRenderObject() as RenderBox;
                  final Offset position =
                      button.localToGlobal(Offset.zero, ancestor: overlay);

                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      position.dx,
                      position.dy +
                          button.size.height, // Show directly below the button
                      position.dx + button.size.width,
                      position.dy + button.size.height + 50,
                    ),
                    items: [
                      PopupMenuItem(
                        value: 'clear_chat',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, color: Colors.black),
                            SizedBox(width: 10),
                            Text("Clear Chat",
                                style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'decline',
                        child: Row(
                          children: const [
                            Icon(Icons.block, color: Colors.black),
                            SizedBox(width: 10),
                            Text("Decline",
                                style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                    color: Colors.white, // Background color
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Smooth rounded corners
                    ),
                  ).then((value) {
                    if (value == 'clear_chat') {
                      _showClearChatDialog(context);
                    } else if (value == 'decline') {
                      _showDeclineDialog(context);
                    }
                  });
                },
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final messageDate =
                              DateTime.parse(message['timestamp']).toLocal();
                          final formattedDate = getMessageDate(messageDate);

                          bool showDateHeader = index == 0 ||
                              getMessageDate(DateTime.parse(
                                          messages[index - 1]['timestamp'])
                                      .toLocal()) !=
                                  formattedDate;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              message['isCurrentUser']
                                  ? ChatBubble(
                                      message: message['message'],
                                      time: message['time'],
                                    )
                                  : ChatBubbleUser(
                                      message: message['message'],
                                      time: message['time'],
                                    ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
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
                      onTap: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, size: 28, color: Colors.white),
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
      ),
    );
  }
}
