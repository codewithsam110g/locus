import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locus/widgets/button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A custom input formatter to auto-insert dashes for the birthday field.
/// The desired format is: YYYY-MM-DD.
class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters.
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    // Limit to at most 8 digits (YYYYMMDD).
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      // After the 4th and 6th digit, add a dash (if not the last character).
      if (i == 3 || i == 5) {
        if (i != digits.length - 1) {
          buffer.write('-');
        }
      }
    }
    // Position the cursor at the end.
    int cursorPosition = buffer.toString().length;
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class Editprofile extends StatefulWidget {
  final String name;
  final String dob;
  const Editprofile({
    super.key,
    required this.name, required this.dob,
  });

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  File? _selectedImage;
  Color avatarColor = Colors.blue; // default background color

  @override
  void initState() {
    super.initState();
    avatarColor = _getRandomColor();
    _birthdayController.text = widget.dob;
    _nameController.text = widget.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  /// Returns a random color.
  Color _getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }


  /// Updates the profile in Supabase.
  Future<void> _updateProfile(BuildContext ctx) async {
    if (!formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    Map<String, dynamic> updates = {
      'name': _nameController.text,
      'dob': _birthdayController.text,
    };

    await supabase.from('profile').update(updates).eq('user_id', userId);
    Navigator.of(ctx).pop();
  }

  /// Opens the image picker to select a new profile image.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      // Optionally, upload the image to Supabase Storage and update the profile.
    }
  }

  /// Builds the circular avatar.
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor:
            _selectedImage == null ? avatarColor : Colors.transparent,
        backgroundImage:
            _selectedImage != null ? FileImage(_selectedImage!) : null,
        child: _selectedImage == null
            ? Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              'Edit Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Electrolize',
              ),
            ),
          ],
        ),
      ),
      body: SizedBox(
        height: height,
        width: width,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.07, vertical: height * 0.02),
            child: Column(
              children: [
                // The avatar is centered at the top.
                Center(child: _buildAvatar()),
                SizedBox(height: height * 0.04),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      Text(
                        'Name',
                        style: TextStyle(
                          fontSize: height * 0.02,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextFormField(
                        controller: _nameController,
                        cursorColor: Theme.of(context).colorScheme.primary,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Name';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: height * 0.02),
                      Text(
                        'Date of Birth (YYYY-MM-DD)',
                        style: TextStyle(
                          fontSize: height * 0.02,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextFormField(
                        controller: _birthdayController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          // Allow digits only, then auto-insert dashes.
                          FilteringTextInputFormatter.digitsOnly,
                          DateTextInputFormatter(),
                        ],
                        cursorColor: Theme.of(context).colorScheme.primary,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Birthday';
                          }
                          // Validate that the input matches the YYYY-MM-DD format.
                          final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                          if (!regex.hasMatch(value)) {
                            return 'Enter birthday in format YYYY-MM-DD';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: height * 0.04),
                      Center(
                        child: Button1(
                          title: 'Save',
                          colors: Colors.white,
                          textColor: Theme.of(context).colorScheme.primary,
                          onTap: () async {
                            if (formKey.currentState!.validate()) {
                              await _updateProfile(context);
                              print('Profile updated successfully');
                            } else {
                              print('Form is invalid');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
