import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:locus/widgets/button.dart';

class Step2 extends StatefulWidget {
  final VoidCallback onNext;
  final String email;
  const Step2({
    super.key,
    required this.onNext,
    required this.email,
  });

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final List<TextEditingController> otpControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(5, (_) => FocusNode());
  bool isLoading = false;
  String? otpError;

  void onFieldChanged(String text, int index) {
    if (text.isNotEmpty && index < otpControllers.length - 1) {
      FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
    } else if (text.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
    }
  }

  @override
  void dispose() {
    // Clean up the focus nodes when the widget is disposed.
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void validateFields() {
    setState(() {
      otpError = otpControllers.any((controller) => controller.text.isEmpty)
          ? 'Please fill all fields'
          : null;
    });
  }

  void showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> sendOtp(String otp) async {
    validateFields();

    if (otpError != null) {
      setState(() {
        otpError = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        '/api/user/verify/password');
    final body = {
      "email": widget.email, // Use email from Step1
      "otp": otp,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        showSnackbar('OTP verified successfully!', Colors.green);
        widget.onNext(); // Proceed to the next step
      } else {
        setState(() {
          otpError = 'Invalid Otp';
        });
      }
    } catch (e) {
      showSnackbar('Check your internet connection', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Focus on next field when user types
  void onFieldSubmitted(int index) {
    if (index < otpControllers.length - 1) {
      FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Step 2: Enter OTP",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              otpControllers.length,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: otpError != null ? Colors.red : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                    ),
                    onChanged: (text) => onFieldChanged(text, index),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (otpError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                otpError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        const SizedBox(height: 30),
        Align(
          alignment: Alignment.center,
          child: Button1(
            title: 'Verify',
            colors: Theme.of(context).colorScheme.primary,
            textColor: Colors.white,
            onTap: () {
              isLoading
              ? () {}
              : () {
                  String otp = otpControllers.map((e) => e.text).join();
                  sendOtp(otp);
                };
            },
          ),
        ),
      ],
    );
  }
}
