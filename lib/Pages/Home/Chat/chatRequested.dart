import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/widgets/chat_bubble_user.dart';
import 'package:locus/widgets/Buttons/InnerButton.dart';
import 'package:locus/widgets/Buttons/OuterButton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Chatforrequested extends StatefulWidget {
  final String img;
  final String id;

  const Chatforrequested({
    super.key,
    required this.id,
    required this.img,
  });

  @override
  State<Chatforrequested> createState() => _ChatforrequestedState();
}

class _ChatforrequestedState extends State<Chatforrequested> {
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;
  final List<String> receivedMessages = [];
  final List<String> sentMessages = [];
  final supabase = Supabase.instance.client;
  String? userName; // Variable to store the fetched username
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        isTyping = _controller.text.isNotEmpty;
      });
    });
    _fetchUserName();
  }

  Future<void> _acceptChatRequest() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // Step 1: Update request status to "accept"
      await supabase
          .from('requests')
          .update({'status': 'accept'})
          .match({
            'reciever_uid': currentUserId,
            'requested_uid': widget.id
          });

      // Step 2: Insert a new chat entry (no sorting needed)
      await supabase.from('chats').insert({
        'uid_1': currentUserId,
        'uid_2': widget.id,
        'is_active': true
      });

      Navigator.of(context).pop();
      // Navigate to chat interface
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (builder) => Chatinterface(
            id: widget.id,
            avatar: Image.asset(widget.img),
          ),
        ),
      );
    } catch (error) {
      print('Error accepting request: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request!')),
      );
    }
  }

  Future<void> _fetchUserName() async {
    final response = await supabase
        .from('profile')
        .select('name')
        .eq('user_id', widget.id)
        .maybeSingle(); // Get a single user or null

    setState(() {
      userName = response?['name'] ?? 'Unknown User';
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildReceivedMessage(String message, String img) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ChatBubbleUser(
        message: message,
        time: '10:20 AM',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(widget.img),
              ),
              const SizedBox(width: 10),
              isLoading
                  ? const CircularProgressIndicator() // Show loading indicator
                  : Text(
                      userName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Electrolize',
                      ),
                    ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            Expanded(
              child: ListView.builder(
                itemCount: receivedMessages.length,
                itemBuilder: (context, index) {
                  return buildReceivedMessage(
                    receivedMessages[index],
                    widget.img,
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Accept message request from ${userName ?? "Unknown User"}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color.fromRGBO(254, 129, 0, 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'If you accept, they will also be able to call you and see info such as your activity and status when you have read messages.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(190, 190, 190, 1),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Outerbutton(text: 'Reject'),
                Innerbutton(
                  function: _acceptChatRequest,
                  text: 'Accept',
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
