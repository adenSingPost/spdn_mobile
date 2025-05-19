import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart'; // Import your AuthService
import '../../utils/constants.dart'; // Import your Constants
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart'; // For date formatting
import '../../pages/main_menu_page.dart';
import 'package:image/image.dart' as img;

class DraftService {
  final AuthService _authService;

  // Constructor to pass AuthService instance
  DraftService(this._authService);

  static Future<File> compressImage(File file) async {
    // Read the image file
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      print('Failed to decode image');
      return file;
    }

    // Resize the image to max 1200px width/height while maintaining aspect ratio
    final resizedImage = img.copyResize(
      image,
      width: image.width > 1200 ? 1200 : image.width,
      height: image.height > 1200 ? 1200 : image.height,
    );

    // Compress the image with quality 85%
    final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

    // Create a temporary file for the compressed image
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }

  // Send all drafts with images to the backend
  Future<void> sendAllDraftsToBackend(BuildContext context, postalCode, int nest) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch all drafts saved in SharedPreferences dynamically
    List<String> draftKeys = [
      'misDeliveryDraft',
      'master_door_draft',
      'return_mailbox_draft'
    ];

    // Map to store combined drafts and images
    Map<String, dynamic> combinedData = {};
    Map<String, List<File>> imagesData = {}; // Map to store image files

    // Iterate through each draft key to get the draft and associated images
    for (String key in draftKeys) {
      String? draftJson = prefs.getString(key);
      if (draftJson != null) {
        Map<String, dynamic> draft = jsonDecode(draftJson);
        // Add the draft data to the combinedData map
        combinedData[key] = draft;

        // Extract photoPaths from the draft and add them to imagesData map
        if (draft['photoPaths'] != null) {
          // Convert each image path into a File object
          imagesData[key] = List<String>.from(draft['photoPaths']).map((path) => File(path)).toList();
        }
      }
    }

    // Get the valid access token
    String? validAccessToken = await _authService.getValidAccessToken(context);

    if (validAccessToken == null) {
      print('Authentication error. Please log in again.');
      return;
    }

    try {
      // Your backend API URL
      var url = Uri.parse('${Constants.backendUrl}/protected/submitAllDrafts');

      // Prepare the API request to send data
      var request = http.MultipartRequest('POST', url)
        ..fields['draftData'] = jsonEncode(combinedData)
        ..fields['postalCode'] = postalCode
        ..fields['nest'] = nest.toString();

      // Add headers
      request.headers['Authorization'] = 'Bearer $validAccessToken';
      request.headers['Connection'] = 'keep-alive';
      request.headers['Keep-Alive'] = 'timeout=60, max=1000';

      // Add images as multipart files
      if (imagesData.isNotEmpty) {
        // Compress all images in parallel first
        Map<String, List<File>> compressedImagesData = {};
        for (var key in imagesData.keys) {
          compressedImagesData[key] = await Future.wait(
            imagesData[key]!.map((file) => compressImage(file))
          );
        }

        // Add all compressed images to request
        for (var key in compressedImagesData.keys) {
          int i = 0;
          for (var compressedFile in compressedImagesData[key]!) {
            i++;
            String newFilename = generateNewFilename(key, postalCode, compressedFile, i);
            
            request.files.add(
              await http.MultipartFile.fromPath(
                'images[]', 
                compressedFile.path, 
                filename: newFilename
              )
            );
          }
        }
      }

      // Send request with timeout
      var response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Read the response stream only once
      final responseBody = await response.stream.bytesToString();
      print('Response body: $responseBody'); // Debug log

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        if (jsonResponse['success'] == true) {
          // Clear the drafts in SharedPreferences upon success
          for (String key in draftKeys) {
            await prefs.remove(key);
          }

          print('All drafts and images successfully sent to the backend!');

          // Navigate to MainMenuPage after clearing preferences
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainMenuPage()),
          );
          return;
        } else {
          print('Failed to send drafts: ${jsonResponse['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send drafts: ${jsonResponse['message']}')),
          );
        }
      } else {
        print('Failed to send drafts: Status code ${response.statusCode}');
        print('Response body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send drafts: Status code ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error sending drafts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending drafts: $e')),
      );
    }
  }

  // Function to clear all drafts in SharedPreferences
  Future<void> clearAllDraft(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // List of all draft keys you want to clear
    List<String> draftKeys = [
      'misDeliveryDraft',
      'master_door_draft',
      'return_mailbox_draft'
    ];

    // Remove all drafts from SharedPreferences
    for (String key in draftKeys) {
      await prefs.remove(key); // Remove draft data
    }

    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All drafts have been cleared!')),
    );
  }

  String generateNewFilename(String draftKey, String postalCode, File imageFile, int index) {
    // Get current date and format it as ddMMyyHHmm (date + hour + minute)
    final now = DateTime.now();
    final formattedDate = DateFormat('ddMMyyHHmm').format(now); 

    // Get the file extension (e.g., jpg, png)
    final extension = imageFile.uri.pathSegments.last.split('.').last;

    // Generate the new filename with draftKey, postalCode, date, and index
    return '$draftKey-$postalCode-$formattedDate-$index.$extension';
  }
}
