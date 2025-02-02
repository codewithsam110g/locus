import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:locus/Pages/Home/Settings/delete.dart';
import 'package:locus/Pages/Home/Settings/feedback.dart';
import 'package:locus/Pages/Home/Settings/reportProblrm.dart';
import 'package:locus/Pages/Home/Settings/updatePassword.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
import 'package:locus/widgets/confirm_to_delete.dart';
import 'package:locus/widgets/editContainer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Settings extends StatefulWidget {
  @override
  State<Settings> createState() => _SettingsState();
}

Future<void> signOut() async {
  const webClientId =
      '814624774577-2ancs6479g4r6g1e5hh94h6te0ks1sb0.apps.googleusercontent.com';
  const iosClientId = '';

  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: iosClientId,
    serverClientId: webClientId,
  );
  final supabase = Supabase.instance.client;
  await googleSignIn.signOut();
  await supabase.auth.signOut();
}

class _SettingsState extends State<Settings> {
  bool _isLoading = false; // To manage loading state

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        children: [
          SizedBox(
            height: height,
            width: width,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.07),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: height * 0.08),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).maybePop();
                            },
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.transparent,
                          )
                        ],
                      ),
                      SizedBox(height: height * 0.05),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Editcontainer(
                                text: 'Update Password',
                                function: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  Future.delayed(const Duration(seconds: 2),
                                      () {
                                    Navigator.of(context)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (builder) => Updatepassword(),
                                      ),
                                    )
                                        .then((_) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    });
                                  });
                                },
                                need: true,
                                icon: Icons.person_4_outlined,
                              ),
                              SizedBox(height: height * 0.02),
                              Editcontainer(
                                text: 'Report Problem',
                                function: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  Future.delayed(Duration(seconds: 2), () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (builder) =>
                                                Reportproblrm()))
                                        .then((_) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    });
                                  });
                                },
                                need: true,
                                icon: Icons.warning_amber,
                              ),
                              SizedBox(height: height * 0.02),
                              Editcontainer(
                                text: 'Feedback',
                                function: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  Future.delayed(Duration(seconds: 2), () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (builder) =>
                                                const FeedBack()))
                                        .then((_) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    });
                                  });
                                },
                                need: true,
                                icon: Icons.feedback_outlined,
                              ),
                              SizedBox(height: height * 0.02),
                              Editcontainer(
                                text: 'Delete my account',
                                function: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  Future.delayed(Duration(seconds: 2), () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (builder) => Delete()))
                                        .then((_) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    });
                                  });
                                },
                                need: true,
                                icon: Icons.delete_outline,
                              ),
                              SizedBox(height: height * 0.02),
                              Editcontainer(
                                text: 'Log out',
                                function: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  Future.delayed(Duration(seconds: 2), () {
                                    ConfirmToDelete(
                                      message:
                                          'Are you sure you want to logout your Tepnoty account?',
                                      () {
                                        signOut();
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return Loginmain();
                                        }));
                                      },
                                    ).showConfirmDialog(context);
                                  });
                                },
                                need: true,
                                icon: Icons.logout,
                              ),
                              SizedBox(height: height * 0.05),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Theme.of(context)
                    .colorScheme
                    .primary, // Customize the color
              ),
            ),
        ],
      ),
    );
  }
}
