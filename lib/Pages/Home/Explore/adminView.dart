import 'package:flutter/material.dart';
import 'package:locus/widgets/chat_bubble.dart';

class Adminview extends StatefulWidget {
  const Adminview({super.key});

  @override
  _AdminviewState createState() => _AdminviewState();
}

class _AdminviewState extends State<Adminview> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];

  void sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add({
          "message": _messageController.text,
          "time": TimeOfDay.now().format(context),
        });
      });

      _messageController.clear();

      // Scroll to the bottom after a short delay to ensure smooth scrolling
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/img/mohan.jpg'),
            ),
            const SizedBox(width: 10),
            Text(
              'Group Name',
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
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Assign the ScrollController
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(
                  message: messages[index]["message"]!,
                  time: messages[index]["time"]!,
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
                    shape: BoxShape.circle, // Makes it circular
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 28, color: Colors.white),
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
    );
  }
}
