import 'package:flutter/material.dart';
import 'package:locus/widgets/button.dart';
import 'package:locus/widgets/inputfeilds.dart';

class Updatepassword extends StatefulWidget {
  @override
  State<Updatepassword> createState() => _UpdatepasswordState();
}

class _UpdatepasswordState extends State<Updatepassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isSubmitted = false;

  String? _passwordError;
  String? _newPasswordError;

  void _validateAndShowDialog() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Password updated successfully"),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 40.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Container(
                  height: 6,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Text(
                'Update Password',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
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
                        // This placeholder ensures the function doesn't return a validation error string
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: true, // Always starts hidden
                      isPasswordField: true,
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
                      controller: _newPasswordController,
                      onTap: (value) {
                        // This placeholder ensures the function doesn't return a validation error string
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: true, // Always starts hidden
                      isPasswordField: true,
                    ),
                    if (_newPasswordError != null)
                      Text(
                        _newPasswordError!,
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
                                _newPasswordError == null) {
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
      _newPasswordError = _newPasswordController.text.isEmpty
          ? "New Password is required"
          : null;
    });
  }

  void _clearFields() {
    _passwordController.clear();
    _newPasswordController.clear();
  }
}
