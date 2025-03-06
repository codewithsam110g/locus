import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Home/about.dart';
import 'dart:math';
import 'package:locus/Pages/Home/Settings/editProfile.dart';
import 'package:locus/Pages/Home/Settings/updatePassword.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? name;
  String? email;
  Color? avatarColor;
  String appVersion = "";
  String? dob;

  @override
  void initState() {
    super.initState();
    doStuff();
    fetchAppVersion();
  }

  Future<void> doStuff() async {
    final supabase = Supabase.instance.client;
    final user_id = supabase.auth.currentUser!.id;
    final prof = await supabase
        .from('profile')
        .select("name,email,dob")
        .eq("user_id", user_id)
        .maybeSingle();

    var birthdayValue = prof?["dob"];
    try {
      DateTime parsedDate = DateTime.parse(birthdayValue.toString());
      dob = parsedDate.toIso8601String().split('T')[0];
    } catch (e) {
      dob = birthdayValue.toString();
    }

    print(dob);
    print(prof?["dob"]);

    setState(() {
      name = prof?["name"] as String?;
      email = prof?["email"] as String?;
      dob = dob;
      avatarColor = getRandomColor();
    });
  }

  Color getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  Future<void> fetchAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
            ),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Electrolize',
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 25, right: 20, top: 30, bottom: 5),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor ?? Colors.grey,
              radius: 50,
              child: Text(
                (name != null && name!.isNotEmpty)
                    ? name![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              name ?? "Loading...",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              email ?? "Loading...",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Editprofile(
                          name: name ?? 'unknown',
                          dob: dob ?? 'unknown',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 12),
                  ),
                  label: const Text(
                    "Edit Profile",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Updatepassword(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  label: const Text(
                    "Update Password",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) => About()));
                  },
                  child: const Text(
                    "Delete Account",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.underline),
                  ),
                ),
                Text(
                  "Version $appVersion",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Sign Out",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
