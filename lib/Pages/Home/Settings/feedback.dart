import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Settings/settings.dart';

class FeedBack extends StatefulWidget {
  const FeedBack({super.key});

  @override
  State<FeedBack> createState() => _FeedBackState();
}

class _FeedBackState extends State<FeedBack> {
  final TextEditingController _feedbackController = TextEditingController();
  String? _feedbackError;
  bool isLoading = false;
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SizedBox(
        height: height,
        width: width,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.07),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.08),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).maybePop();
                          },
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                        Text(
                          'Feedback',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontFamily: 'Electrolize',
                          ),
                        ),
                        Icon(
                          Icons.arrow_back,
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.07),
                    Text(
                      'What\'s your opinion on Tepnoty?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    TextField(
                      controller: _feedbackController,
                      minLines: 7,
                      maxLines: 9,
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'I love Tepnoty',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        errorText: _feedbackError, // Display error message
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 2,
                            style: BorderStyle.solid,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 2,
                            style: BorderStyle.solid,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          // Check if the user has entered feedback
                          _feedbackError = _feedbackController.text.isEmpty
                              ? 'Please provide your feedback.'
                              : null;

                          // If there are no errors, proceed with loading state
                          isLoading = _feedbackError == null;
                          selected = _feedbackError == null;
                        });

                        // If no errors, proceed with the loading state
                        if (isLoading) {
                          await Future.delayed(const Duration(seconds: 2));
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (builder) => Settings(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            width: 1.5,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          color: selected
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Show CircularProgressIndicator in the center of the screen when isLoading is true
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
