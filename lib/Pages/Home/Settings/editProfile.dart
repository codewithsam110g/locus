import 'package:flutter/material.dart';
import 'package:locus/widgets/button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Editprofile extends StatefulWidget {
  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _bdayController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  //final TextEditingController _userIdController = TextEditingController();
  //final TextEditingController _emailController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    doStuff();
  }

  Future<void> doStuff() async {
    final user_id = supabase.auth.currentUser!.id;
    final prof = await supabase
        .from("profile")
        .select("name, gender, dob")
        .eq("user_id", user_id)
        .maybeSingle();
    setState(() {
      _nameController.text = prof!["name"] as String;
      _genderController.text = prof!["gender"] as String;
      _bdayController.text = prof!["dob"] as String;
    });
  }

  Future<void> updateProfile() async {
    final user_id = supabase.auth.currentUser!.id;
    await supabase.from("profile").update({
      "name": _nameController.text.trim(),
      "gender": _genderController.text.trim(),
      "dob": _bdayController.text.trim()
    }).eq("user_id", user_id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    //_userIdController.dispose();
    //_emailController.dispose();
    _bdayController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  bool _isValidDateFormat(String input) {
    final RegExp dateRegExp = RegExp(
        r'^\d{4}\/((0)[0-9]|(1)[0-2])\/([0-2][0-9]|(3)[0-1])$'); // YYYY/MM/DD
    return dateRegExp.hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SizedBox(
        height: height,
        width: width,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.07),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.08),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.tertiary,
                              fontFamily: 'Electrolize'),
                        ),
                        const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                    Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: height * 0.04),
                          Text(
                            'Name',
                            style: TextStyle(
                              fontSize: height * 0.02,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          TextFormField(
                            controller: _nameController,
                            cursorColor: Theme.of(context).colorScheme.tertiary,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            decoration: const InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: height * 0.01),
                          // Text(
                          //   'User Id',
                          //   style: TextStyle(
                          //     fontSize: height * 0.02,
                          //     fontWeight: FontWeight.w600,
                          //     color: Theme.of(context).colorScheme.tertiary,
                          //   ),
                          // ),
                          // TextFormField(
                          //   controller: _userIdController,
                          //   cursorColor: Theme.of(context).colorScheme.tertiary,
                          //   style: TextStyle(
                          //     color: Theme.of(context).colorScheme.tertiary,
                          //   ),
                          //   decoration: const InputDecoration(
                          //     enabledBorder: UnderlineInputBorder(
                          //       borderSide: BorderSide(color: Colors.white),
                          //     ),
                          //     focusedBorder: UnderlineInputBorder(
                          //       borderSide: BorderSide(color: Colors.white),
                          //     ),
                          //   ),
                          //   validator: (value) {
                          //     if (value == null || value.isEmpty) {
                          //       return 'Please enter your User Id';
                          //     } else if (!RegExp(r'^[a-zA-Z0-9]+$')
                          //         .hasMatch(value)) {
                          //       return 'User Id should contain only letters and numbers';
                          //     }
                          //     return null;
                          //   },
                          // ),
                          // SizedBox(height: height * 0.01),
                          // Text(
                          //   'Email',
                          //   style: TextStyle(
                          //     fontSize: height * 0.02,
                          //     fontWeight: FontWeight.w600,
                          //     color: Theme.of(context).colorScheme.tertiary,
                          //   ),
                          // ),
                          // TextFormField(
                          //   controller: _emailController,
                          //   cursorColor: Theme.of(context).colorScheme.tertiary,
                          //   style: TextStyle(
                          //     color: Theme.of(context).colorScheme.tertiary,
                          //   ),
                          //   decoration: const InputDecoration(
                          //     enabledBorder: UnderlineInputBorder(
                          //       borderSide: BorderSide(color: Colors.white),
                          //     ),
                          //     focusedBorder: UnderlineInputBorder(
                          //       borderSide: BorderSide(color: Colors.white),
                          //     ),
                          //   ),
                          //   validator: (value) {
                          //     if (value == null || value.isEmpty) {
                          //       return 'Please enter your Email';
                          //     } else if (!RegExp(
                          //             r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          //         .hasMatch(value)) {
                          //       return 'Please enter a valid email address';
                          //     }
                          //     return null;
                          //   },
                          // ),
                          // SizedBox(height: height * 0.02),
                          Text(
                            'Gender (M/F)',
                            style: TextStyle(
                              fontSize: height * 0.02,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          TextFormField(
                            controller: _genderController,
                            cursorColor: Theme.of(context).colorScheme.tertiary,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            decoration: const InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Gender (M/F)';
                              } else if (value.toLowerCase() != 'male' && value.toLowerCase() != 'female') {
                                return 'Gender must be either Male or Female';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: height * 0.02),
                          Text(
                            'Birthday (dd/MM/yyyy)',
                            style: TextStyle(
                              fontSize: height * 0.02,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          TextFormField(
                            controller: _bdayController,
                            cursorColor: Theme.of(context).colorScheme.tertiary,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            decoration: const InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Birthday';
                              } else if (!_isValidDateFormat(value)) {
                                return 'Enter birthday in format dd/MM/yyyy';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: height * 0.02),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.04),
                    Align(
                      alignment: Alignment.center,
                      child: Button1(
                        title: 'Save',
                        colors: Colors.white,
                        textColor: Theme.of(context).colorScheme.primary,
                        onTap: () async {
                          if (formKey.currentState!.validate()) {
                            await updateProfile();
                            Navigator.of(context).pop();
                          } else {
                            //TODO: Add Alert Dialog
                            print('Form is invalid');
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
