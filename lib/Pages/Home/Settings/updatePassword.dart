import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Settings/settings.dart';
import 'package:locus/widgets/button.dart';
import 'package:locus/widgets/inputfeilds.dart';

class Updatepassword extends StatefulWidget {
  @override
  State<Updatepassword> createState() => _UpdatepasswordState();
}

class _UpdatepasswordState extends State<Updatepassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitted = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _passwordError;
  String? _confirmPasswordError;

  void _validateAndShowDialog() {
    if (_formKey.currentState!.validate()) {
      // Show the dialog after successful validation
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color.fromRGBO(
                21, 21, 21, 1), // AlertDialog background color
            title: Container(
              padding: const EdgeInsets.all(8), // Padding inside the circle
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green, // Border color
                  width: 2, // Border width
                ),
              ),
              child: const Icon(
                Icons.done,
                color: Colors.green, // Icon color
                size: 24,
              ),
            ),
            content: const Column(
              mainAxisSize:
                  MainAxisSize.min, // Ensure the column size fits its content
              children: [
                Text(
                  'Congratulations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your Password was Updated!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              Center(
                child: Button1(
                  title: 'Continue',
                  colors: Theme.of(context).colorScheme.primary,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Settings()),
                    ); // Navigate to the Main screen
                  },
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Image.asset('assets/img/locus1.png'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Container(
                  height: 9,
                  width: 180,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(5)),
                ),
              ),
              Text(
                'Upadeted Password',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'Electrolize'),
              ),
              Form(
                key: _formKey,
                autovalidateMode: _isSubmitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Inputfields(
                      title: 'Enter Current Password',
                      emoji: const Icon(Icons.lock),
                      controller: _passwordController,
                      onTap: (value) {
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: !_isPasswordVisible,
                    ),
                    if (_passwordError != null)
                      Text(
                        _passwordError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 25),
                    Inputfields(
                      title: 'Enter New Password',
                      emoji: const Icon(Icons.lock),
                      controller: _confirmPasswordController,
                      onTap: (value) {
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: !_isConfirmPasswordVisible,
                    ),
                    if (_confirmPasswordError != null)
                      Text(
                        _confirmPasswordError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Button1(
                          title: 'Confirm',
                          colors: Theme.of(context).colorScheme.primary,
                          textColor: Colors.white,
                          onTap: () {
                            setState(() {
                              _isSubmitted = true;
                              _validateForm();
                            });
                            if (_formKey.currentState!.validate() &&
                                _passwordError == null &&
                                _confirmPasswordError == null) {
                              _clearFields();
                              _validateAndShowDialog(); // Show dialog on successful registration
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _validateForm() {
    setState(() {
      _passwordError =
          _passwordController.text.isEmpty ? "Password is required" : null;
      _confirmPasswordError = _confirmPasswordController.text.isEmpty
          ? "Confirm Password is required"
          : _confirmPasswordController.text != _passwordController.text
              ? "Passwords do not match"
              : null;
    });
  }

  void _clearFields() {
    _passwordController.clear();
    _confirmPasswordController.clear();
  }
}
