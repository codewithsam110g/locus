import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChatBubbleUser extends StatelessWidget {
  final String message;
  final String time;

  const ChatBubbleUser({
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
    bool multiLineText = isMultiline(message, screenWidth * 0.6, textStyle);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3.0, left: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 50.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: multiLineText
                                ? EdgeInsets.only(bottom: 10)
                                : const EdgeInsets.only(right: 65.0),
                            child: Text(
                              message,
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 60,
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
