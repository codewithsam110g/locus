import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locus/Pages/LoginRegister/login.dart';
import 'package:locus/Pages/LoginRegister/register/registerMain.dart';
import 'package:locus/widgets/customContainer.dart';
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

class _LoginmainState extends State<Loginmain> {
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
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'Electrolize',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: Customcontainer(
                  widget: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  text: 'Continue with Email',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (builder) => Login(),
                      ),
                    );
                  },
                ),
              ),
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
