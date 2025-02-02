import 'dart:ui';
import 'package:flutter/material.dart';

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

  // Widget to display received messages with grouping
  Widget buildReceivedMessage(String message, int index) {
    bool showProfileImage = true;
    if (index > 0 && index < receivedMessages.length) {
      showProfileImage = false;
    }

    return GestureDetector(
      onLongPress: () {
        showDeleteDialog(index, false);
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProfileImage)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 15,
                  backgroundImage: AssetImage('assets/img/mohan.jpg'),
                ),
              )
            else
              const SizedBox(
                width: 38,
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Widget to display sent messages with grouping
  Widget buildSentMessage(String message, int index) {
    bool showProfileImage = true;
    if (index > 0 && index < sentMessages.length) {
      showProfileImage = false;
    }

    return GestureDetector(
      onLongPress: () {
        showDeleteDialog(index, true);
      },
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(15),
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (showProfileImage)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: CircleAvatar(
                  radius: 15,
                  backgroundImage: AssetImage('assets/img/mohan.jpg'),
                ),
              )
            else
              const SizedBox(
                width: 38,
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    // ignore: deprecated_member_use
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
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: SizedBox(
          height: height,
          width: width,
          child: Stack(
            children: [
              Padding(
                padding:
                    EdgeInsets.only(left: width * 0.07, right: width * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.06),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).maybePop();
                              },
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Image.asset(widget.img),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  widget.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: Color.fromRGBO(14, 191, 53, 1),
                                      size: 15,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Active Now',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color.fromRGBO(
                                            155, 155, 155, 1),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(width: width * 0.04),
                        GestureDetector(
                          onTapDown: (TapDownDetails details) {
                            showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                      details.globalPosition.dx + 10,
                                      details.globalPosition.dy + 20,
                                      details.globalPosition.dx + 40,
                                      details.globalPosition.dy + 40,
                                    ),
                                    items: [
                                      const PopupMenuItem(
                                        value: 'Clear Chat',
                                        child: Text(
                                          'Clear Chat',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'Report',
                                        child: Text(
                                          'Report',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'Block',
                                        child: Text(
                                          'Block',
                                          style: TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                    elevation: 10,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                    shadowColor: Colors.black)
                                .then((value) {
                              switch (value) {
                                case 'Clear Chat':
                                  showClearChatDialog();
                                  break;
                                case 'Report':
                                  // Handle report action
                                  break;
                                case 'Block':
                                  // Handle block action
                                  break;
                              }
                            });
                          },
                          child: Icon(
                            Icons.more_vert_outlined,
                            color:
                                Theme.of(context).colorScheme.secondary,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Message list
                    Expanded(
                      child: ListView.builder(
                        controller:
                            _scrollController, // Attach the ScrollController
                        itemCount:
                            receivedMessages.length + sentMessages.length,
                        itemBuilder: (context, index) {
                          if (index < receivedMessages.length) {
                            return buildReceivedMessage(
                              receivedMessages[index], // No change here
                              index, // Pass index here
                            );
                          } else {
                            return buildSentMessage(
                              sentMessages[index -
                                  receivedMessages
                                      .length], // Corrected index calculation for sent messages
                              index -
                                  receivedMessages
                                      .length, // Pass index for the sent messages separately
                            );
                          }
                        },
                      ),
                    ),
                    // Input field and send button
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 0),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.only(bottom: 0),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: height * 0.03, horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    width: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        cursorColor: Colors.white,
                                        decoration: const InputDecoration(
                                          hintText: 'Message..',
                                          border: InputBorder.none,
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    if (!isTyping) // Show the 'add' icon only when the user isn't typing
                                      Icon(
                                        Icons.add,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isTyping ? Icons.send : Icons.mic,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (isTyping) {
                                    sendMessage();
                                  } else {
                                    // Implement voice recording functionality
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
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
