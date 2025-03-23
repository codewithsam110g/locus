import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
import 'package:locus/Pages/LoginRegister/register/register2.dart';
import 'package:locus/widgets/Buttons/newButton.dart';
import 'package:locus/widgets/customContainer.dart';
import 'package:locus/widgets/inputfeilds.dart';
import 'package:locus/widgets/otherOptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Registermain extends StatefulWidget {
  @override
  State<Registermain> createState() => _RegistermainState();
}

Future<void> _googleSignIn(BuildContext ctx) async {
  const webClientId =
      '814624774577-2ancs6479g4r6g1e5hh94h6te0ks1sb0.apps.googleusercontent.com';
  const iosClientId = '';

  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: iosClientId,
    serverClientId: webClientId,
  );

  try {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw 'Google Sign-In canceled by user.';
    }
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    final supabase = Supabase.instance.client;

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    Navigator.of(ctx).push(MaterialPageRoute(builder: (context) {
      return Register2();
    }));
  } on PlatformException catch (e) {
    // Handle Google Sign-In errors specifically
    if (e.code == 'network_error') {
      throw 'Network error, please check your internet connection.';
    } else if (e.code == 'sign_in_canceled') {
      throw 'User canceled the Google Sign-In process.';
    } else if (e.code == '10') {
      throw 'API Exception 10: Invalid OAuth configuration. Check your webClientId and SHA-1 setup.';
    } else {
      print(e);
      throw 'Google Sign-In error: ${e.message}';
    }
  } catch (e) {
    throw 'Sign-In Failed: $e';
  }
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

class _RegistermainState extends State<Registermain> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cnfPasswordController = TextEditingController();

  bool _isSubmitted = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _cnfPasswordError;

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
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Register Now!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'Electrolize',
                  ),
                ),
              ),
              Form(
                key: _formKey,
                autovalidateMode: _isSubmitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
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
                      obscureText: true, // Always starts hidden
                      isPasswordField: true,
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
                      obscureText: true, // Always starts hidden
                      isPasswordField: true,
                    ),
                    if (_cnfPasswordError != null)
                      Text(
                        _cnfPasswordError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: CustomButton(
                        text: _isLoading
                            ? 'Loading...'
                            : 'Next', // Change button text when loading
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Colors.white,
                        onPressed: _isLoading
                            ? () {} // Disable button while loading
                            : () async {
                                setState(() {
                                  _isSubmitted = true;
                                  _validateForm();
                                });

                                if (_formKey.currentState!.validate() &&
                                    _passwordError == null &&
                                    _emailError == null &&
                                    _cnfPasswordError == null) {
                                  setState(() {
                                    _isLoading = true; // Show loading state
                                  });

                                  try {
                                    await signUpNewUser(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => Register2(),
                                      ),
                                    );
                                  } catch (e) {
                                    print(e);
                                    setState(() {
                                      String errorMessage = e.toString();

                                      if (errorMessage.contains(
                                          "Password should be at least 6 characters")) {
                                        _passwordError =
                                            "Password should be at least 6 characters.";
                                      } else if (errorMessage.contains(
                                          "User already registered")) {
                                        _emailError =
                                            "This email is already registered. Try logging in.";
                                      } else if (errorMessage
                                              .contains("Failed host lookup") ||
                                          errorMessage.contains(
                                              "RealtimeSubscribeStatus.channelError") ||
                                          errorMessage.contains(
                                              "WebSocketChannelException")) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Network error! Please check your internet connection.",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: Colors
                                                .red, // Red background for network error
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "An unexpected error occurred. Please try again.",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    });
                                  } finally {
                                    setState(() {
                                      _isLoading = false; // Reset loading state
                                    });
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text('Or'),
                  ),
                  Expanded(
                    child: Divider(),
                  ),
                ],
              ),
              SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: Customcontainer(
                  widget: Image.asset(
                    'assets/img/google.png',
                    height: 30,
                    width: 30,
                  ),
                  text: 'Continue with Google',
                  onTap: () async {
                    _googleSignIn(context);
                  },
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
      ),
    );
  }
}
