import 'package:flutter/material.dart';
import 'package:locus/widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Adminview extends StatefulWidget {
  const Adminview({super.key});

  @override
  _AdminviewState createState() => _AdminviewState();
}

class _AdminviewState extends State<Adminview> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _inputScrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  final supabase = Supabase.instance.client;
  String groupName = "Group Name";
  String com_id = "";
  bool isLoading = true;
  String imgURL = 'assets/img/mohan.jpg';

  @override
  void initState() {
    super.initState();
    fetchCommunityInfo();
  }

  Future<void> fetchCommunityInfo() async {
    final userId = supabase.auth.currentUser!.id;
    final comData = await supabase
        .from("profile")
        .select("com_id, community(*)")
        .eq("user_id", userId)
        .single();

    setState(() {
      com_id = comData['com_id'];
      groupName = comData['community']['title'];
      imgURL = comData['community']['logo_link'];
    });

    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final fetchedMessages = await supabase
        .from("community_messages")
        .select("message, created_at")
        .eq("com_id", com_id)
        .order("created_at", ascending: true);

    setState(() {
      messages = fetchedMessages;
      isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    _messageController.clear();
    _inputScrollController.jumpTo(0);
    await supabase.from("community_messages").insert({
      "com_id": com_id,
      "message": messageText,
      "created_at": DateTime.now().toUtc().toIso8601String(),
    });

    fetchMessages();
  }

  String formatDateTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    int hour = dateTime.hour;
    String period = hour >= 12 ? "PM" : "AM";

    // Convert to 12-hour format
    hour = hour > 12 ? hour - 12 : hour;
    hour = hour == 0 ? 12 : hour; // Handle midnight (0:00) as 12 AM

    return "${hour.toString()}:${dateTime.minute.toString().padLeft(2, '0')} $period";
  }

  String getDateHeader(String timestamp) {
    DateTime messageDate = DateTime.parse(timestamp).toLocal();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime messageDay =
        DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) {
      return "Today";
    } else if (messageDay == yesterday) {
      return "Yesterday";
    } else if (now.difference(messageDate).inDays < 7) {
      // Within the last week
      return DateFormat('EEEE')
          .format(messageDate); // Day name (e.g., "Monday")
    } else {
      // More than a week ago
      return DateFormat('MMM d, yyyy')
          .format(messageDate); // e.g., "Mar 23, 2025"
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: imgURL.contains("asset")
                  ? AssetImage(imgURL) as ImageProvider
                  : NetworkImage(imgURL) as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(
              groupName,
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
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No messages yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];

                          bool showDateHeader = false;
                          String dateHeader =
                              getDateHeader(message["created_at"]);
                          if (index == 0) {
                            showDateHeader = true;
                          } else {
                            String prevDateHeader = getDateHeader(
                                messages[index - 1]["created_at"]);
                            showDateHeader = dateHeader != prevDateHeader;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        dateHeader,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ChatBubble(
                                message: message["message"],
                                time: formatDateTime(message["created_at"]),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbVisibility: MaterialStateProperty.all(true),
                        thickness: MaterialStateProperty.all(6),
                        radius: const Radius.circular(10),
                        thumbColor: MaterialStateProperty.all(Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.6)),
                        mainAxisMargin: 4,
                        crossAxisMargin: 4,
                      ),
                    ),
                    child: Scrollbar(
                      controller: _inputScrollController,
                      child: TextFormField(
                        controller: _messageController,
                        scrollController: _inputScrollController,
                        minLines: 1,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.newline,
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
