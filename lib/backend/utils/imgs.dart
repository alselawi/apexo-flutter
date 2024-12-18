import 'dart:io';
import 'package:apexo/backend/utils/constants.dart';
import 'package:apexo/backend/utils/safe_dir.dart';
import 'package:apexo/backend/utils/strip_id_from_file.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

Future<void> createDirectory(String path) async {
  final Directory dir = Directory(path);
  if (await dir.exists()) {
    return;
  } else {
    await dir.create(recursive: true);
  }
}

Future<bool> checkIfFileExists(String name) async {
  final File file = File(join(await filesDir(), name));
  return await file.exists();
}

Future<File> getOrCreateFile(String name) async {
  await createDirectory(await filesDir());
  return File(join(await filesDir(), name));
}

Future<ImageProvider> getImage(String name) async {
  // in case of web, we serve images from the server
  if (kIsWeb) {
    await Hive.openBox(webImagesStore);
    final imageUrl = Hive.box(webImagesStore).get(name);
    if (imageUrl != null) {
      return NetworkImage(imageUrl);
    }
  }

  if (await checkIfFileExists(name)) {
    return Image.file(await getOrCreateFile(name)).image;
  } else {
    return const AssetImage("assets/images/missing.png");
  }
}

Future<File> savePickedImage(XFile image, String newName) async {
  final File newImage = await getOrCreateFile(newName);
  if (await newImage.exists()) return newImage;
  return await File(image.path).copy(newImage.path);
}

Future<File> saveImageFromUrl(String imageUrl, [String? givenName]) async {
  final imageName = givenName ?? stripIDFromFileName(imageUrl.split('/').last);

  // in case of web, we store the image link in the hive store
  if (kIsWeb) {
    await Hive.openBox(webImagesStore);
    await Hive.box(webImagesStore).put(imageName, imageUrl);
    return File(imageUrl);
  }

  final File newImage = await getOrCreateFile(imageName);
  if (await newImage.exists()) return newImage;

  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode == 200) {
    return await newImage.writeAsBytes(response.bodyBytes);
  } else {
    throw Exception('Failed to download image');
  }
}

Future<String?> getImageExtensionFromURL(String imageUrl) async {
  try {
    // Make HEAD request to get headers without downloading the whole file
    final response = await http.head(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      if (contentType != null) {
        // Map MIME types to extensions
        switch (contentType.toLowerCase()) {
          case 'image/jpeg':
          case 'image/jpg':
            return '.jpg';
          case 'image/png':
            return '.png';
          case 'image/gif':
            return '.gif';
          case 'image/webp':
            return '.webp';
          case 'image/bmp':
            return '.bmp';
          case 'image/heic':
            return '.heic';
          default:
            return '.${contentType.split('/').last}';
        }
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}
