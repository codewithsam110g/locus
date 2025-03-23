import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Home/about.dart';
import 'dart:math';
import 'package:locus/Pages/Home/Settings/editProfile.dart';
import 'package:locus/Pages/Home/Settings/updatePassword.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
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
  String? photoURL;
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
        .select("name,email,dob,image_link")
        .eq("user_id", user_id)
        .maybeSingle();

    var birthdayValue = prof?["dob"];
    try {
      DateTime parsedDate = DateTime.parse(birthdayValue.toString());
      dob = parsedDate.toIso8601String().split('T')[0];
    } catch (e) {
      dob = birthdayValue.toString();
    }

    setState(() {
      name = prof?["name"] as String?;
      email = prof?["email"] as String?;
      photoURL = prof?["image_link"] as String?;
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

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.6,
          minChildSize: 0.2,
          expand: false,
          builder: (_, ScrollController) {
            return Center(
              child: Updatepassword(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final double horizontalPadding = screenSize.width * 0.06;
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
              backgroundColor:
                  photoURL == null ? (avatarColor ?? Colors.grey) : null,
              backgroundImage:
                  photoURL != null ? NetworkImage(photoURL!) : null,
              radius: 50,
              child: photoURL == null
                  ? Text(
                      (name != null && name!.isNotEmpty)
                          ? name![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
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
            const SizedBox(height: 15),
            // Middle Section - Buttons
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.04),
              child: OrientationBuilder(
                builder: (context, orientation) {
                  return orientation == Orientation.portrait ||
                          screenSize.width < 600
                      ? Column(
                          children: [
                            _buildEditProfileButton(context, isSmallScreen),
                            SizedBox(height: screenSize.height * 0.02),
                            _buildUpdatePasswordButton(context, isSmallScreen),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                child: _buildEditProfileButton(
                                    context, isSmallScreen)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildUpdatePasswordButton(
                                    context, isSmallScreen)),
                          ],
                        );
                },
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => About(),
                      ),
                    );
                  },
                  child: const Text(
                    "About",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  "Version $appVersion",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (builder) => Loginmain(),
                      ),
                    );
                  },
                  child: const Text(
                    "Sign Out",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => Editprofile(
                name: name ?? 'unknown',
                dob: dob ?? 'unknown',
                photoURL: photoURL ?? "NAN",
              ),
            ),
          )
              .then((val) {
            doStuff();
          });
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.4,
              )),
          padding: EdgeInsets.symmetric(
            horizontal: 25,
            vertical: isSmallScreen ? 10 : 12,
          ),
        ),
        icon: Icon(
          Icons.edit,
          color: Theme.of(context).colorScheme.primary,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          "Edit Profile",
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: isSmallScreen ? 14 : 16),
        ),
      ),
    );
  }

  Widget _buildUpdatePasswordButton(BuildContext context, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showBottomSheet();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSmallScreen ? 10 : 12,
          ),
        ),
        icon: Icon(
          Icons.lock_reset,
          color: Colors.white,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          "Update Password",
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }
}
