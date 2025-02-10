import 'package:flutter/material.dart';
import 'package:locus/Pages/LoginRegister/register/register2.dart';
import 'package:locus/widgets/button.dart';
import 'package:locus/widgets/inputfeilds.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
import 'package:locus/widgets/otherOptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Register1 extends StatefulWidget {
  @override
  State<Register1> createState() => _Register1State();
}

class _Register1State extends State<Register1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cnfPasswordController = TextEditingController();

  bool _isSubmitted = false;

  String? _emailError;
  String? _passwordError;
  String? _cnfPasswordError;

  Future<void> signUpNewUser(String? email, String? pwd) async {
    final supabase = Supabase.instance.client;
    AuthResponse res =
        await supabase.auth.signUp(email: email, password: pwd ?? "");
    print(res);
    res =
        await supabase.auth.signInWithPassword(email: email, password: pwd ?? "");
    print(res);
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
                      title: 'Email ID',
                      emoji: const Icon(Icons.email),
                      controller: _emailController,
                      onTap: (value) {
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: false,
                    ),
                    if (_emailError != null)
                      Text(
                        _emailError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    SizedBox(
                      height: 25,
                    ),
                    Inputfields(
                      title: 'Password',
                      emoji: const Icon(Icons.lock),
                      controller: _passwordController,
                      onTap: (value) {
                        // This placeholder ensures the function doesn't return a validation error string
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: true,
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
                      controller: _cnfPasswordController,
                      onTap: (value) {
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: true,
                    ),
                    if (_cnfPasswordError != null)
                      Text(
                        _cnfPasswordError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Button1(
                          title: 'Next',
                          colors: Theme.of(context).colorScheme.primary,
                          textColor: Colors.white,
                          onTap: () async {
                            setState(() {
                              _isSubmitted = true;
                              _validateForm();
                            });
                            if (_formKey.currentState!.validate() &&
                                _passwordError == null &&
                                _emailError == null &&
                                _cnfPasswordError == null) {
                              await signUpNewUser(_emailController.text.trim(),
                                  _passwordController.text.trim());
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => Register2()),
                              );
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
      _passwordError =
          _passwordController.text.isEmpty ? "Password is required" : null;
      _emailError = _emailController.text.isEmpty ? "Email is required" : null;
      _cnfPasswordError =
          _cnfPasswordController.text.isEmpty ? "User ID is required" : null;
      _cnfPasswordError =
          _cnfPasswordController.text != _passwordController.text
              ? "Passwords Dont Match"
              : null;
    });
  }
}
