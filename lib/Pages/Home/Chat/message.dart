import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Message extends StatefulWidget {
  @override
  _MessageState createState() => _MessageState();
}

class _MessageState extends State<Message> {
  final TextEditingController _controller = TextEditingController();
  bool _isButtonEnabled = false;
  final int _maxChars = 50;
  bool isSending = false;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkTextField);
  }

  void _checkTextField() {
    setState(() {
      _isButtonEnabled = _controller.text.trim().isNotEmpty && _controller.text.length <= _maxChars ;
    });
  }

  Future<void> _sendMessage() async {
     if (!_isButtonEnabled || isSending) return;
    setState(() {
      isSending = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final double latitude = position.latitude;
      final double longitude = position.longitude;
      final String message = _controller.text.trim();

      await supabase.from('messages').insert({
        'user_id': supabase.auth.currentUser?.id,
        'message': message,
        'location': {'lat': latitude, 'lng': longitude}, // Store as JSON
      });

      _controller.clear();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }finally{
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 30),
                ),
                Row(
                  children: [
                    Text(
                      '${_controller.text.length}/${_maxChars}'
                    ),
                    SizedBox(width: 10,),
                    ElevatedButton(
                      onPressed: _isButtonEnabled && !isSending ? _sendMessage : null,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) => _isButtonEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Send',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                    ),
                   
                    
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _controller,
                    maxLength: _maxChars,
                    minLines: 7,
                    maxLines: 9,
                    cursorColor: Theme.of(context).colorScheme.secondary,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Send Message..',
                      hintStyle: TextStyle(color: Colors.grey),
                      counterText: "", // Hide default counter
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
