import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:locus/widgets/button.dart';
import 'package:locus/widgets/inputfeilds.dart';

class Step1 extends StatefulWidget {
  final Function(String) onNext; // Changed the type to accept a String argument

  const Step1({super.key, required this.onNext});
  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  String? emailError;

  void validateFields() {
    setState(() {
      emailError = emailController.text.isEmpty ? 'Enter username' : null;
    });
  }

  bool isValidEmail(String email) {
    final rguktRegex = RegExp(r"^[nsro]\d{6}@rguktn\.ac\.in$");
    return rguktRegex.hasMatch(email);
  }

  Future<void> sendEmail() async {
    final email = emailController.text.trim();
    validateFields();

    if (email.isEmpty) {
      setState(() {
        emailError = 'Email cannot be empty.';
      });
      return;
    }

    if (!isValidEmail(email)) {
      setState(() {
        emailError = 'Please use a valid RGUKT email.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      emailError = null;
    });

    final url = Uri.parse('/api/user/recover/password');
    final body = {"email": email};

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        widget.onNext(email);
      } else {
        final errorResponse = json.decode(response.body);
        setState(() {
          emailError = errorResponse['message'] ?? 'Unknown error occurred.';
        });
      }
    } catch (e) {
      setState(() {
        emailError = 'Check your internet connection.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Step 1: Enter your Email",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Inputfields(
          title: 'Email',
          emoji: const Icon(Icons.person_2_outlined),
          controller: emailController,
          onTap: (value) {
            return null;
          },
          keyBoard1: false,
          obscureText: false,
        ),
        if (emailController != null)
          Text(
            emailController.text!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        const SizedBox(height: 30),
        Align(
          alignment: Alignment.center,
          child: Button1(
            title: 'Send',
            colors: Theme.of(context).colorScheme.primary,
            textColor: Colors.white,
            onTap: () {
              if (!isLoading) sendEmail();
            },
          ),
        ),
      ],
    );
  }
}
