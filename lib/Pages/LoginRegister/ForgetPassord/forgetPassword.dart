import 'package:flutter/material.dart';
import 'package:locus/Pages/LoginRegister/ForgetPassord/Step1.dart';
import 'package:locus/Pages/LoginRegister/ForgetPassord/Step2.dart';
import 'package:locus/Pages/LoginRegister/ForgetPassord/Step3.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({
    super.key,
  });

  @override
  _ForgetPasswordState createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  int currentStep = 1;
  String email = ''; // Store the email from Step1

  @override
  Widget build(BuildContext context) {
    return (Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 80.0, left: 40, right: 40),
              child: Image.asset('assets/img/locus1.png'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                height: 9,
                width: 180,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(5)),
              ),
            ),
            // Text(
            //   'Login',
            //   style: TextStyle(
            //       fontSize: 48,
            //       fontWeight: FontWeight.w500,
            //       color: Theme.of(context).colorScheme.primary,
            //       fontFamily: 'Electrolize'),
            // ),
            // Steps Container
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Step Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStepIndicator(currentStep >= 1), // Step 1
                      _buildLine(currentStep >= 2), // Line after Step 1
                      _buildStepIndicator(currentStep >= 2), // Step 2
                      _buildLine(currentStep >= 3), // Line after Step 2
                      _buildStepIndicator(currentStep == 3), // Step 3
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Step Widgets
                  if (currentStep == 1)
                    Step1(
                      onNext: (String enteredEmail) {
                        setState(() {
                          email = enteredEmail;
                          currentStep = 2;
                        });
                      },
                    ),
                  if (currentStep == 2)
                    Step2(
                      email: email,
                      onNext: () {
                        setState(() {
                          currentStep = 3;
                        });
                      },
                    ),
                  if (currentStep == 3)
                    Step3(
                      email: email,
                      onNext: () {
                        // Final logic after Step 3 is completed
                        showSnackbar('Password reset completed!', Colors.green);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (builder) => Loginmain()),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildStepIndicator(bool isCompleted) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 20)
          : null,
    );
  }

  Widget _buildLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 3,
        color: isCompleted ? Colors.green : Colors.grey,
      ),
    );
  }

  // Helper function to show a Snackbar
  void showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
