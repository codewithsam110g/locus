import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/widgets/chat_bubble_user.dart';
import 'package:locus/widgets/Buttons/InnerButton.dart';
import 'package:locus/widgets/Buttons/OuterButton.dart';

class Chatforrequested extends StatefulWidget {
  final String img;
  final String name;

  const Chatforrequested({
    super.key,
    required this.name,
    required this.img,
  });

  @override
  State<Chatforrequested> createState() => _ChatforrequestedState();
}

class _ChatforrequestedState extends State<Chatforrequested> {
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;
  final List<String> receivedMessages = [
   
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
    super.dispose();
  }

  void showConfirmationDialog(BuildContext context, String title,
      String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(title, style: TextStyle(color: Colors.black)),
          content: Text(message, style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context)
                    .pop(); // Close the dialog after confirmation
              },
              child: Text(
                'Confirm',
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget to display received messages
  Widget buildReceivedMessage(String message, String img) {
    return Align(
        alignment: Alignment.centerLeft,
        child: ChatBubbleUser(
          message: message,
          time: '10:20 AM',
        ));
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(
              flex: 2,
            ),
            // Message list
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
                'Accept message request from ${widget.name} ?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color.fromRGBO(254, 129, 0, 1),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'If you accept, they will also be able to call you and see info such as your activity and status when you have read messages.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(190, 190, 190, 1),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Outerbutton(text: 'Reject'),
                Innerbutton(
                  function: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (builder) => Chatinterface(
                          name: widget.name,
                          img: widget.img,
                        ),
                      ),
                    );
                  },
                  text: 'Accept',
                ),
              ],
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
