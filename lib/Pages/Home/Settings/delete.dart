import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';

class Delete extends StatefulWidget {
  const Delete({super.key});

  @override
  _DeleteState createState() => _DeleteState();
}

class _DeleteState extends State<Delete> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _descriptionError;
  String? selectedReason;
  String? _reasonError;
  bool isLoading = false; // State for loading
  bool selected = false;
  final List<String> reasons = [
    'I no longer need the app',
    'I didn\'t like the user interface',
    'I found an alternative app',
    'I\'m experiencing technical issues',
    'I\'m concerned about privacy or security',
    'Other'
  ];

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content:
            const Text('Are you sure you want to logout your Locus account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (builder) => Loginmain(),
                ),
              );
            },
            child: const Text('Confirm to Logout'),
          ),
        ],
      ),
    );
  }

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
              child: Column(
                children: [
                  SizedBox(height: height * 0.08),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.tertiary,
                          fontFamily: 'Electrolize',
                        ),
                      ),
                      const Icon(
                        Icons.arrow_back,
                        size: 1,
                        color: Colors.transparent,
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.07),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What\'s your primary reason for deleting the account?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          DropdownButtonFormField<String>(
                            value: selectedReason,
                            items: reasons.map((reason) {
                              return DropdownMenuItem(
                                value: reason,
                                child: Text(
                                  reason,
                                  style:const  TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedReason = value;
                                _reasonError =
                                    null; // Clear the error when a reason is selected
                              });
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              errorText:
                                  _reasonError, // Display the error message if any
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  width: 0,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  width: 0,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                            hint: const Text(
                              'Select a reason',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: height * 0.03),
                          Text(
                            'Please let us know how we can improve.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText:
                                  'The more you describe,\n The better we understand',
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              errorText:
                                  _descriptionError, // Display error message if any
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (text) {
                              setState(() {
                                _descriptionError =
                                    null; // Clear error when text is entered
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Button always at the bottom
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        // Check if the user has entered the required details
                        _descriptionError = _descriptionController.text.isEmpty
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
                        await Future.delayed( const Duration(seconds: 2));
                        _showConfirmationDialog();
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
                          'Delete Anyway',
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
                  SizedBox(height: height * 0.02),
                ],
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
