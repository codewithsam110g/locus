import 'package:flutter/material.dart';

class Chatcontainer extends StatefulWidget {
  /// Instead of an image asset, the new UI expects a custom avatar widget.
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
    required this.date
  }) : super(key: key);

  @override
  State<Chatcontainer> createState() => _ChatcontainerState();
}

class _ChatcontainerState extends State<Chatcontainer> {
  @override
  Widget build(BuildContext context) {
    // Determine if this message is sent by the current user.
    final bool isSend = widget.type == 'send';

    // For sent messages, use a green bubble; for received messages, use white.
    final bubbleColor = isSend ? Theme.of(context).colorScheme.secondary : Colors.white;
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
                  // Message text.
                  Text(
                    widget.text.isNotEmpty
                        ? widget.text
                        : 'No message available',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
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
                            onTap: () {},
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
