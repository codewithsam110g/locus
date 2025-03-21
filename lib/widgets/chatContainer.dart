import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class Chatcontainer extends StatefulWidget {
  final Widget avatar;
  final String text;
  final String name;
  final VoidCallback function;
  final String type;
  final String date;

  const Chatcontainer({
    Key? key,
    required this.avatar,
    required this.text,
    required this.name,
    required this.function,
    required this.type,
    required this.date,
  }) : super(key: key);

  @override
  State<Chatcontainer> createState() => _ChatcontainerState();
}

class _ChatcontainerState extends State<Chatcontainer> {
  // Create a ScrollController instance
  final ScrollController _scrollController = ScrollController();
  
  void shareText(String text) {
    Share.share(text);
  }
  
  // Dispose the controller when the widget is removed
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this message is sent by the current user.
    final bool isSend = widget.type == 'send';

    // For sent messages, use a green bubble; for received messages, use white.
    final bubbleColor =
        isSend ? Theme.of(context).colorScheme.secondary : Colors.white;
    final textColor = isSend ? Colors.black : Colors.black;
    final dateColor = isSend ? Colors.black : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the avatar with an active indicator.
          widget.avatar,
          const SizedBox(width: 8),
          // Message bubble container.
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                border: Border.all(
                  color: Colors.black.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender's name (or "You" for sent messages).
                  Text(
                    isSend
                        ? "You"
                        : (widget.name.isNotEmpty ? widget.name : 'Unknown'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Message text with scrolling capability
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 120, // Set maximum height for the text area
                    ),
                    child: Scrollbar(
                      controller: _scrollController, // Add the controller here
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(10),
                      child: SingleChildScrollView(
                        controller: _scrollController, // Also add it here
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          widget.text.isNotEmpty
                              ? widget.text
                              : 'No message available',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Placeholder for the message time.
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 15,
                          color: dateColor,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              shareText("${widget.name} is Sharing This Text:\n${widget.text}\nAt Time:${widget.date}");
                            },
                            child: Icon(
                              Icons.reply,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!isSend)
                            GestureDetector(
                              onTap: widget.function,
                              child: Icon(
                                Icons.message,
                                color: textColor,
                              ),
                            ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}