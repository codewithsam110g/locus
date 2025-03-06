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
          msg:
              "Location permission is permanently denied. Enable it in settings.");
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

    final locationData = {"lat": position.latitude, "long": position.longitude};

    // Insert into database
    await supabase.from("community").insert({
      "com_id": com_id,
      "tags": tags,
      "title": title,
      "desc": desc,
      "location": locationData
    });

    await supabase
        .from("profile")
        .update({"com_id": com_id}).eq("user_id", userId);
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: 8,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Center(
                  child: const Text(
                    "Create Group",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        fontFamily: 'Electrolize'),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                // Title Field
                _buildInputField("Title", "Enter group title", _titleController,
                    _titleError),
                const SizedBox(height: 15),

                // Description Field
                _buildInputField("Description", "Enter group description",
                    _descriptionController, _descriptionError,
                    maxLines: 4),
                const SizedBox(height: 15),

                // Logo Picker
                _buildImagePicker(),
                SizedBox(
                  height: 10,
                ),

                // Tag Dropdown
                _buildTagDropdown(),

                const SizedBox(height: 25),

                // Add Button
                Button1(
                  title: 'Request Group',
                  colors: Theme.of(context).colorScheme.primary,
                  textColor: Colors.white,
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
      ),
    );
  }

  // Input field widget
  Widget _buildInputField(String label, String hint,
      TextEditingController controller, String? error,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            errorText: error,
          ),
        ),
      ],
    );
  }

  // Image Picker widget
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Logo",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _chooseFile,
              icon: const Icon(
                Icons.image,
                color: Colors.grey,
              ),
              label: const Text(
                "Choose Image",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100], 
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), 
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (_selectedImage != null)
              const Icon(Icons.check_circle, color: Colors.green),
            if (_logoError != null)
              Text(_logoError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // Tag Dropdown widget
  Widget _buildTagDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tag",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _selectedTag,
          items: ['Organization', 'Building', 'Community', 'Project']
              .map((tag) =>
                  DropdownMenuItem<String>(value: tag, child: Text(tag)))
              .toList(),
          onChanged: (value) => setState(() => _selectedTag = value),
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              errorText: _tagError,
              hintText: 'Select Tag'),
        ),
      ],
    );
  }
}
