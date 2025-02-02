import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Settings/settings.dart';
import 'package:locus/Pages/Home/Settings/editProfile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? name;
  String? email;

  @override
  void initState() {
    super.initState();
    doStuff();
  }

  Future<void> doStuff() async {
    final supabase = Supabase.instance.client;
    final user_id = supabase.auth.currentUser!.id;
    final prof = await supabase
        .from('profile')
        .select("name,email")
        .eq("user_id", user_id).maybeSingle();
    setState(() {
      name = prof!["name"] as String?;
      email = prof!["email"] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.asset(
                    'assets/img/locus1.png',
                    width: 170,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    Icons.close,
                    size: 30,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/img/mohan.jpg'),
                    radius: 60,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    name ?? "Loading",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  // Text(
                  //   'mohanveera_9',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.w400,
                  //     color: Colors.black,
                  //   ),
                  // ),
                  Text(
                    email ?? "Loading",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: Column(
                children: [
                  Divider(),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (builder) => Editprofile(),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Icon(
                                  Icons.edit_square,
                                  color: Color.fromRGBO(129, 129, 129, 1),
                                ),
                              ),
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromRGBO(129, 129, 129, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (builder) => Settings(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Icon(
                                  Icons.settings,
                                  color: Color.fromRGBO(129, 129, 129, 1),
                                ),
                              ),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromRGBO(129, 129, 129, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 10.0),
                              child: Icon(
                                Icons.help,
                                color: Color.fromRGBO(129, 129, 129, 1),
                              ),
                            ),
                            Text(
                              'Help',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(129, 129, 129, 1),
                              ),
                            ),
                          ],
                        ),
                        VerticalDivider(),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 10.0),
                              child: Icon(
                                Icons.info,
                                color: Color.fromRGBO(129, 129, 129, 1),
                              ),
                            ),
                            Text(
                              'About',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(129, 129, 129, 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
