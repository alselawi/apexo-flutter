import 'dart:io';
import 'package:apexo/utils/constants.dart';
import 'package:apexo/utils/hash.dart';
import 'package:apexo/utils/safe_dir.dart';
import 'package:apexo/utils/strip_id_from_file.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart' as path;
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
  final File file = File(path.join(await filesDir(), name));
  return await file.exists();
}

Future<File> getOrCreateFile(String name) async {
  await createDirectory(await filesDir());
  return File(path.join(await filesDir(), name));
}

// copies a given image to local folder and upload it to the server
Future<String> handleNewImage({required String rowID, required String targetPath, bool updateModel = true}) async {
  final bool fromLink = targetPath.startsWith("http");

  String extension;
  File imgFile;

  if (fromLink) {
    extension = await getImageExtensionFromURL(targetPath) ?? ".jpg";
  } else {
    extension = path.extension(targetPath);
  }

  final imgName = simpleHash(targetPath) + extension;

  if (fromLink) {
    imgFile = await saveImageFromUrl(targetPath, imgName);
  } else {
    imgFile = await savePickedImage(File(targetPath), imgName);
  }

  await appointments.uploadImg(rowID, imgFile.path);

  return imgName;
}

final imgMemoryCache = <String, ImageProvider?>{};

Future<ImageProvider?> getImage(String rowID, String name) async {
  if (imgMemoryCache.containsKey(name)) {
    return imgMemoryCache[name];
  } else if (name == "https://person.alisaleem.workers.dev/") {
    final link = "$name?no-cache=$rowID";
    if (imgMemoryCache.containsKey(link)) {
      return imgMemoryCache[link];
    }
    final img = Image.network(link).image;
    return imgMemoryCache[link] = img;
  } else {
    final img = await _getImage(rowID, name);
    imgMemoryCache[name] = img;
    if (imgMemoryCache.length > 100) {
      imgMemoryCache.remove(imgMemoryCache.keys.first);
    }
    return img;
  }
}

Future<ImageProvider?> _getImage(String rowID, String name) async {
  // Web platform doesn't support local files
  if (kIsWeb) {
    final imgUrl = await appointments.remote!.getImageLink(rowID, name);
    return imgUrl == null ? null : NetworkImage(imgUrl);
  }

  // if the file exists locally, return it
  else if (await checkIfFileExists(name)) {
    return Image.file(await getOrCreateFile(name)).image;
  }

  // if the file doesn't exist locally, download it from the server
  else {
    final imgUrl = await appointments.remote!.getImageLink(rowID, name);
    if (imgUrl == null) {
      return null;
    } else {
      final download = await saveImageFromUrl(imgUrl, name);
      return Image.file(download).image;
    }
  }
}

Future<File> savePickedImage(File image, String newName) async {
  final File newImage = await getOrCreateFile(newName);
  if (await newImage.exists()) return newImage;
  return await image.copy(newImage.path);
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