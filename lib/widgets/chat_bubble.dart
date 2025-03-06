import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.time,
  });

  bool isMultiline(String text, double maxWidth, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 2, // Check if the text exceeds two lines
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(
      color: Colors.black,
      fontSize: 16,
    );

    double screenWidth = MediaQuery.of(context).size.width;
    bool multiLineText = isMultiline(message, screenWidth * 0.7, textStyle);

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(left: 60), // Space for the timestamp
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.7, // Prevents overflow
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                        topLeft: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: multiLineText
                              ? EdgeInsets.zero
                              : const EdgeInsets.only(right: 60.0),
                          child: Text(
                            message,
                            style: textStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
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
