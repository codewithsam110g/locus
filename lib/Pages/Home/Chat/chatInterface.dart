import 'package:flutter/material.dart';
import 'package:locus/widgets/chat_bubble_user.dart';
import 'package:locus/widgets/chat_bubble.dart';

class Chatinterface extends StatefulWidget {
  final String img;
  final String name;

  const Chatinterface({
    super.key,
    required this.name,
    required this.img,
  });

  @override
  State<Chatinterface> createState() => _ChatinterfaceState();
}

class _ChatinterfaceState extends State<Chatinterface> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  final List<String> receivedMessages = [
    "Hello, how are you?",
    "I'm doing great, thanks!",
    "How about you?"
  ];
  final List<String> sentMessages = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to show the delete dialog
  void showDeleteDialog(int index, bool isSentMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (isSentMessage) {
                    sentMessages.removeAt(index);
                  } else {
                    receivedMessages.removeAt(index);
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Function to clear the chat
  void clearChat() {
    setState(() {
      sentMessages.clear();
      receivedMessages.clear();
    });
  }

  // Function to show a confirmation dialog for clearing the chat
  void showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text('Are you sure you want to clear the chat?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                clearChat();
                Navigator.of(context).pop();
              },
              child: const Text('Clear Chat'),
            ),
          ],
        );
      },
    );
  }

  // Send message function
  void sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        sentMessages.add(_controller.text);
        _controller.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
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
    return WillPopScope(
      onWillPop: () async {
        if (FocusScope.of(context).isFirstFocus) {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard if it's open
          return false; // Prevents back button closing the app directly
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(widget.img),
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
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Message list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: receivedMessages.length + sentMessages.length,
                  itemBuilder: (context, index) {
                    if (index < receivedMessages.length) {
                      return ChatBubbleUser(
                        message: receivedMessages[index],
                        time: '12:34 PM', // Example time
                      );
                    } else {
                      return ChatBubble(
                        message: sentMessages[index - receivedMessages.length],
                        time: '12:34 PM', // Example time
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10),
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
                        shape: BoxShape.circle, // Makes it circular
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send,
                            size: 28, color: Colors.white),
                        onPressed: sendMessage,
                        padding: const EdgeInsets.all(12), // Increases tap area
                        constraints:
                            const BoxConstraints(), // Removes default button padding
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
