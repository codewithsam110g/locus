import 'package:image_picker/image_picker.dart';
import "package:cloudinary/cloudinary.dart";

final cloudinary = Cloudinary.signedConfig(
    apiKey: "349789929425887",
    apiSecret: "K58t9dLWHWClQiGyWaa8JXeLQFQ",
    cloudName: "dqy1ryqsk");

Future<String?> uploadFile(XFile? file) async {
  if (file == null) return "NAN";
  final response = await cloudinary.upload(
    file: file.path,
    fileName: file.name,
    fileBytes: await file.readAsBytes(),
    resourceType: CloudinaryResourceType.image,
  );

  if (response.isSuccessful) {
    return response.secureUrl;
  } else {
    return "NAN";
  }
}
