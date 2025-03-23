import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago; // Import the timeago package
import 'dart:async';
import 'package:intl/intl.dart'; // Import for date parsing

class Chatcontainer extends StatefulWidget {
  final Widget avatar;
  final String text;
  final String name;
  final VoidCallback function;
  final String type;
  final dynamic timestamp; // Can accept String or DateTime

  const Chatcontainer({
    Key? key,
    required this.avatar,
    required this.text,
    required this.name,
    required this.function,
    required this.type,
    required this.timestamp,
  }) : super(key: key);

  @override
  State<Chatcontainer> createState() => _ChatcontainerState();
}

class _ChatcontainerState extends State<Chatcontainer> {
  final ScrollController _scrollController = ScrollController();
  late Timer _timer; // Timer to update the time display
  String _relativeTime = ''; // Store the formatted relative time
  DateTime? _messageTime; // Store the parsed DateTime

  void shareText(String text) {
    Share.share(text);
  }

  @override
  void initState() {
    super.initState();
    // Parse the timestamp to DateTime
    _messageTime = _parseTimestamp(widget.timestamp);

    // Set initial relative time
    _updateRelativeTime();

    // Set up a timer to update the relative time every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _updateRelativeTime();
      }
    });
  }

  // Parse different timestamp formats to DateTime
  DateTime? _parseTimestamp(dynamic timestamp) {

    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      // If the timestamp is empty or invalid, use current time
      if (timestamp.isEmpty) {
        return DateTime.now();
      }

      // Try to parse time in common formats
      try {
        // Special case for "HH:mm dd-MM-yyyy" format (e.g., "00:53 22-03-2025")
        if (timestamp.contains(':') && timestamp.contains('-')) {
          try {
            final parts = timestamp.split(' ');
            if (parts.length == 2) {
              final timeParts = parts[0].split(':');
              final dateParts = parts[1].split('-');

              if (timeParts.length == 2 && dateParts.length == 3) {
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                final day = int.parse(dateParts[0]);
                final month = int.parse(dateParts[1]);
                final year = int.parse(dateParts[2]);

                return DateTime(year, month, day, hour, minute);
              }
            }
          } catch (e) {
            print("Error parsing special format: $e");
            // Continue to other formats
          }
        }

        // First check for Firestore timestamp (number)
        if (timestamp.contains("Timestamp")) {
          // Extract seconds from Firestore timestamp format
          final RegExp regex = RegExp(r'seconds=(\d+)');
          final match = regex.firstMatch(timestamp);
          if (match != null && match.groupCount >= 1) {
            final seconds = int.parse(match.group(1)!);
            return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }

        // Check if it's a simple time format like "11:00"
        if (timestamp.contains(':')) {
          final parts = timestamp.split(':');
          if (parts.length == 2 &&
              !timestamp.contains('-') &&
              !timestamp.contains('/')) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);

            // Get today's date
            final now = DateTime.now();
            // Create a datetime with today's date and the given time
            var messageTime =
                DateTime(now.year, now.month, now.day, hour, minute);

            // If the time is in the future (because the message was from yesterday),
            // subtract a day to make it in the past
            if (messageTime.isAfter(now)) {
              messageTime = messageTime.subtract(const Duration(days: 1));
            }

            return messageTime;
          }
        }

        // Try standard formats with intl package
        final formats = [
          "yyyy-MM-dd HH:mm:ss",
          "yyyy-MM-ddTHH:mm:ss",
          "dd/MM/yyyy HH:mm",
          "MM/dd/yyyy HH:mm",
          "HH:mm:ss",
          "HH:mm",
          "HH:mm dd-MM-yyyy", // Added for "00:53 22-03-2025" format
          "dd-MM-yyyy HH:mm", // Added alternative format
        ];

        for (final format in formats) {
          try {
            final dateTime = DateFormat(format).parse(timestamp);
            return dateTime;
          } catch (e) {
            // Continue to the next format
          }
        }

        // Try standard ISO format
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          // Continue to next method
        }

        // Try milliseconds/seconds since epoch
        if (timestamp.length >= 10 && int.tryParse(timestamp) != null) {
          final value = int.parse(timestamp);
          // If milliseconds (13 digits typically)
          if (timestamp.length >= 13) {
            return DateTime.fromMillisecondsSinceEpoch(value);
          }
          // If seconds (10 digits typically)
          else {
            return DateTime.fromMillisecondsSinceEpoch(value * 1000);
          }
        }
      } catch (e) {
        print("Error parsing timestamp: $e");
      }
    } else if (timestamp is int) {
      // Handle numeric timestamp (epoch)
      if (timestamp > 100000000000) {
        // Milliseconds (13 digits)
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        // Seconds (10 digits)
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    } else if (timestamp is Map) {
      // Handle Firestore timestamp object
      if (timestamp.containsKey('seconds')) {
        final seconds = timestamp['seconds'] as int;
        final nanoseconds = timestamp['nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds / 1000000).round(),
        );
      }
    }

    // If all parsing fails, return current time
    print("Failed to parse timestamp, using current time");
    return DateTime.now();
  }

  // Format the timestamp as a relative time string using timeago package
  void _updateRelativeTime() {
    if (_messageTime == null) {
      setState(() {
        _relativeTime = 'a moment ago';
      });
      return;
    }

    setState(() {
      _relativeTime = timeago.format(_messageTime!);
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
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
                      // Display the relative time instead of the date string
                      Text(
                        _relativeTime,
                        style: TextStyle(
                          fontSize: 15,
                          color: dateColor,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              shareText(
                                  "${widget.name} is Sharing This Text:\n${widget.text}\nAt Time:$_relativeTime");
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
