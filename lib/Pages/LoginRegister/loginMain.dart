import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locus/Pages/Home/mainScreen.dart';
import 'package:locus/Pages/LoginRegister/ForgetPassord/forgetPassword.dart';
import 'package:locus/Pages/LoginRegister/register/registerMain.dart';
import 'package:locus/widgets/Buttons/newButton.dart';
import 'package:locus/widgets/customContainer.dart';
import 'package:locus/widgets/inputfeilds.dart';
import 'package:locus/widgets/otherOptions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Loginmain extends StatefulWidget {
  @override
  State<Loginmain> createState() => _LoginmainState();
}

Future<AuthResponse> _googleSignIn() async {
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
    return await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
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

Future<void> doStuff() async {
  await requestPermission();
  await getFCMToken();
}

Future<void> requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Permission granted");
  } else {
    print("Permission denied");
  }
}

Future<void> setFcmToken(String? token) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;
  await supabase
      .from("profile")
      .update({"fcm_token": token}).eq("user_id", userId);
}

Future<void> getFCMToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
  await setFcmToken(token);
}

Future<void> signInWithEmail(
    BuildContext ctx, String? email, String? pwd) async {
  final supabase = Supabase.instance.client;
  final AuthResponse res =
      await supabase.auth.signInWithPassword(email: email, password: pwd ?? "");
  await doStuff();
  Navigator.of(ctx).push(
    MaterialPageRoute(
      builder: (builder) => Mainscreen(),
    ),
  );
}

class _LoginmainState extends State<Loginmain> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitted = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      setState(() {
        _emailError = "Email cannot be empty";
        _passwordError = "Password cannot be empty";
        _isLoading = false;
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _emailError = "Email cannot be empty";
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = "Password cannot be empty";
        _isLoading = false;
      });
      return;
    }

    try {
      await signInWithEmail(context, email, password);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (e.toString().contains("invalid_credentials")) {
        _passwordError = "Incorrect email or password";
      } else if (e.toString().contains("Failed host lookup")) {
        _passwordError = "No internet connection. Please check your network.";
      } else {
        _passwordError = "Something went wrong. Please try again.";
      }
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
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Welcome Back!',
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
                      title: 'Email',
                      emoji: const Icon(Icons.person_2),
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
                      title: 'Enter Password',
                      emoji: const Icon(Icons.lock),
                      controller: _passwordController,
                      onTap: (value) {
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
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          print("onTap");
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (builder) => ForgetPassword(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: CustomButton(
                        text: _isLoading ? 'Loading...' : 'Login',
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Colors.white,
                        onPressed: _isLoading ? () {} : _handleLogin,
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
                  Expanded(child: Divider()),
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
                  onTap: () {
                    _googleSignIn();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Otheroptions(
                  text1: 'Do not have an account? ',
                  text2: 'Register',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (builder) => Registermain(),
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
