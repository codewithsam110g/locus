import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locus/widgets/button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';


class Newgroup extends StatefulWidget {
  @override
   createState() => _NewgroupState();
}

class _NewgroupState extends State<Newgroup> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _descriptionError;
  XFile? _selectedImage;
  String? _selectedTag;
  String? _titleError;

  String? _logoError;
  String? _tagError;

  final supabase = Supabase.instance.client;

  // Function to pick an image from the gallery
  Future<void> _chooseFile() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  // Function to validate fields and show errors
  bool _validateFields() {
    bool isValid = true;
    setState(() {
      _titleError =
          _titleController.text.isEmpty ? 'Please enter a title' : null;
      _descriptionError = _descriptionController.text.isEmpty
          ? 'Please enter a description'
          : null;
      //_logoError = _selectedImage == null ? 'Please select a logo' : null;
      _tagError = _selectedTag == null ? 'Please select a tag' : null;
      isValid = _titleError == null &&
          _descriptionError == null &&
          _logoError == null &&
          _tagError == null;
    });
    return isValid;
  }
  
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
  
    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return null;
    }
  
    // Request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied.");
        return null;
      }
    }
  
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: "Location permission is permanently denied. Enable it in settings.");
      return null;
    }
  
    // Get current position
    return await Geolocator.getCurrentPosition();
  }
  
  Future<void> requestCommunity() async {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    final tags = _selectedTag!.trim();
    final com_id = title.replaceAll(" ", "_");
    final userId = supabase.auth.currentUser!.id;
  
    // Fetch the user's profile
    final prof = await supabase
        .from("profile")
        .select("com_id")
        .eq("user_id", userId)
        .single();
  
    if (prof["com_id"] != null) {
      Fluttertoast.showToast(msg: "You already have a group!");
      return;
    }
  
    // Get the current location
    Position? position = await _getCurrentLocation();
    if (position == null) {
      return; // Stop execution if location is not available
    }
  
    final locationData = {
      "lat": position.latitude,
      "long": position.longitude
    };
  
    // Insert into database
    await supabase.from("community").insert({
      "com_id": com_id,
      "tags": tags,
      "title": title,
      "desc": desc,
      "location": locationData
    });
  
    await supabase.from("profile").update({"com_id": com_id}).eq("user_id", userId);
  }


  // Function to show a dialog box
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Are you sure you want to request the new group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await requestCommunity();
              Navigator.pop(context);
            },
            child: const Text('Request'),
          ),
        ],
      ),
    ).then((value) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Perform pop when clicked
                  },
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Add New Group",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Electrolize',
                ),
              ),
              const SizedBox(height: 30),

              // Row for Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Title:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter group title',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _titleError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            6,
                          ), // Adjust the radius as needed
                          borderSide:
                              BorderSide.none, // Removes the default border
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Column for Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Description:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter group description',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _descriptionError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          6,
                        ), // Adjust the radius as needed
                        borderSide:
                            BorderSide.none, // Removes the default border
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Row for Logo
              Row(
                children: [
                  const Text(
                    "Logo:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _chooseFile,
                    child: const Text("Choose File"),
                  ),
                  const SizedBox(width: 10),
                  if (_selectedImage != null)
                    const Text(
                      "Image selected",
                      style: TextStyle(color: Colors.white),
                    ),
                  if (_logoError != null)
                    Text(
                      _logoError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              // Row for Add tags dropdown
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Add tags:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTag,
                      items:
                          ['Organization', 'Building', 'Community', 'Project']
                              .map((tag) => DropdownMenuItem<String>(
                                    value: tag,
                                    child: Text(tag),
                                  ))
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTag = value;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Select a tag',
                        hintStyle: TextStyle(color: Colors.grey),
                        errorText: _tagError,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Add button
              Button1(
                title: 'Add',
                colors: Colors.white,
                textColor: Theme.of(context).colorScheme.primary,
                onTap: () {
                  if (_validateFields()) {
                    _showConfirmationDialog();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
