import 'package:flutter/material.dart';
import 'package:locus/widgets/button.dart';
import 'package:locus/widgets/inputfeilds.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
import 'package:locus/widgets/otherOptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Register extends StatefulWidget {
  @override
  State<Register> createState() => _RegisterState();
}

Future<void> signUpNewUser(String? email, String? pwd) async {
  final supabase = Supabase.instance.client;
  AuthResponse res =
      await supabase.auth.signUp(email: email, password: pwd ?? "");
  print(res);
  res =
      await supabase.auth.signInWithPassword(email: email, password: pwd ?? "");
  print(res);
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitted = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;

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
                'Register',
                style: TextStyle(
                    fontSize: 48,
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
                      title: 'Username or ID',
                      emoji: const Icon(Icons.person_2_outlined),
                      controller: _nameController,
                      onTap: (value) {
                        // This placeholder ensures the function doesn't return a validation error string
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: false,
                    ),
                    if (_usernameError != null)
                      Text(
                        _usernameError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    SizedBox(
                      height: 25,
                    ),
                    Inputfields(
                      title: 'Enter Password',
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
                    SizedBox(
                      height: 25,
                    ),
                    Inputfields(
                      title: 'Confirm Password',
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
                          title: 'Register',
                          colors: Theme.of(context).colorScheme.primary,
                          textColor: Colors.white,
                          onTap: () {
                            setState(() {
                              _isSubmitted = true;
                              _validateForm();
                            });
                            if (_formKey.currentState!.validate() &&
                                _usernameError == null &&
                                _passwordError == null &&
                                _confirmPasswordError == null) {
                              signUpNewUser(_nameController.text,
                                  _passwordController.text);
                            }
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Otheroptions(
                        text1: 'Already have an account? ',
                        text2: 'Login',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (builder) => Loginmain(),
                            ),
                          );
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 9,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(5),
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
      _usernameError =
          _nameController.text.isEmpty ? "Username is required" : null;
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
    _nameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }
}
