import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Settings/settings.dart';

class Reportproblrm extends StatefulWidget {
  @override
  State<Reportproblrm> createState() => _ReportproblrmState();
}

class _ReportproblrmState extends State<Reportproblrm> {
  String? _descriptionError;
  String? _reasonError;
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;
  bool selected = false;

  String? selectedReason;
  final List<String> reasons = [
    'I no longer need the app',
    'I didn\'t like the user interface',
    'I found an alternative app',
    'I\'m experiencing technical issues',
    'I\'m concerned about privacy or security',
    'Other'
  ];

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
                    SizedBox(
                      height: height * 0.08,
                    ),
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
                          'Report a Problem',
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
                        )
                      ],
                    ),
                    SizedBox(
                      height: height * 0.07,
                    ),
                    Text(
                      'Please select your primary reason for reporting this issue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    // Dropdown for selecting a reason
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: reasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            width: 1.5,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            width: 1.5,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        errorText: _reasonError,
                      ),
                      hint: Text(
                        'Select a reason',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    SizedBox(height: height * 0.02),
                    Text(
                      'Describe your concern',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    TextField(
                      controller: _descriptionController,
                      minLines: 7,
                      maxLines: 9,
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black ,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText:
                            'The more you describe,\n The better we understand!',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            width: 0,
                            style: BorderStyle.solid,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            width: 0,
                            style: BorderStyle.solid,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        errorText: _descriptionError,
                      ),
                    ),
                    SizedBox(
                      height: height * 0.03,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Take a Screenshot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Take screen recording',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Upload from Gallary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: height * 0.03,
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          // Check if the user has entered the required details
                          _descriptionError =
                              _descriptionController.text.isEmpty
                                  ? 'Please provide more details.'
                                  : null;
                          _reasonError = selectedReason == null
                              ? 'Please select a reason.'
                              : null;

                          // If there are no errors, proceed with loading state
                          isLoading =
                              _descriptionError == null && _reasonError == null;
                          selected =
                              _descriptionError == null && _reasonError == null;
                        });

                        // If no errors, show the confirmation dialog after a delay
                        if (isLoading) {
                          await Future.delayed(const Duration(seconds: 2));
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (builder) => Settings(),
                            ),
                          );
                          setState(() {
                            isLoading = false;
                            selected = false;
                          });
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
          ],
        ),
      ),
    );
  }
}
