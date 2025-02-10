import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/mainScreen.dart';
import 'package:locus/widgets/button.dart';
import 'package:locus/widgets/inputfeilds.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
import 'package:locus/widgets/otherOptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Register2 extends StatefulWidget {
  @override
  State<Register2> createState() => _Register2State();
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

class _Register2State extends State<Register2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bdayController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isSubmitted = false;

  String? _bdayError;
  String? _genderError;
  String? _nameError;

  Future<void> createProfile() async {
    final supabase = Supabase.instance.client;
    final user_id = supabase.auth.currentUser!.id;
    final email = supabase.auth.currentUser!.email;
    final name = _nameController.text.trim();
    final bday = _bdayController.text.trim();
    final gender = _genderController.text.trim();

    await supabase.from("profile").insert({
      "user_id": user_id,
      "email": email,
      "name": name,
      "dob": bday,
      "gender": gender
    });

    await doStuff();
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
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Text(
                'Register',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'Electrolize',
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
                    const SizedBox(height: 50),
                    Inputfields(
                      title: 'Name',
                      emoji: const Icon(Icons.email),
                      controller: _nameController,
                      onTap: (value) {
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: false,
                    ),
                    if (_nameError != null)
                      Text(
                        _nameError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 30),
                    Inputfields(
                      title: 'Birthday',
                      emoji: const Icon(Icons.cake_outlined),
                      controller: _bdayController,
                      onTap: (value) {
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: false,
                      suffixIcon:
                          Icons.calendar_today_outlined, // Calendar icon
                      suffixIconTap: () async {
                        DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _bdayController.text =
                                '${selectedDate.toLocal()}'.split(' ')[0];
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 25),
                    Inputfields(
                      title: 'Gender',
                      emoji: const Icon(Icons.email),
                      controller: _genderController,
                      onTap: (value) {
                        return null;
                      },
                      keyBoard1: false,
                      obscureText: false,
                    ),
                    if (_genderError != null)
                      Text(
                        _genderError!,
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
                                _bdayError == null &&
                                _genderError == null &&
                                _nameError == null) {
                              await createProfile();
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return Mainscreen();
                              }));
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
      _nameError = _nameController.text.isEmpty ? "Name is Required" : null;
      _bdayError = _bdayController.text.isEmpty ? "Birthday is required" : null;
      _genderError =
          _genderController.text.isEmpty ? "Gender is required" : null;
    });
  }
}
