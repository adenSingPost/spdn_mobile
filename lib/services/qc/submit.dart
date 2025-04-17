import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart'; // Import your AuthService
import '../../utils/constants.dart'; // Import your Constants
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // For date formatting
import '../../pages/main_menu_page.dart';

class DraftService {
  final AuthService _authService;

  // Constructor to pass AuthService instance
  DraftService(this._authService);

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
      var url = Uri.parse('${Constants.backendUrl}/protected/submitAllDrafts'); // Replace with your backend URL

      // Prepare the API request to send data
      var request = http.MultipartRequest('POST', url)
        ..fields['draftData'] = jsonEncode(combinedData)  // Add all drafts
        ..fields['postalCode'] = postalCode  // Add postalCode field
        ..fields['nest'] = nest.toString();  // Add the nest field

      // Add images as multipart files
      if (imagesData.isNotEmpty) {
        for (var key in imagesData.keys) {
          int i = 0;  // Initialize the index variable

          for (var imageFile in imagesData[key]!) {
            i++;  // Increment the index

            // Generate the new filename with the index included
            String newFilename = generateNewFilename(key, postalCode, imageFile, i);

            // Add each image file as a multipart file with the new filename
            var multipartFile = await http.MultipartFile.fromPath('images[]', imageFile.path, filename: newFilename);
            request.files.add(multipartFile);
          }
        }
      }

      // Add Bearer Token to headers for authentication
      request.headers['Authorization'] = 'Bearer $validAccessToken';

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        // Clear the drafts in SharedPreferences upon success
        for (String key in draftKeys) {
          await prefs.remove(key); // Remove draft data
        }

        // Show a success message (optional)
        print('All drafts and images successfully sent to the backend!');

        // Navigate to MainMenuPage after clearing preferences
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenuPage()),  // Navigate to MainMenuPage
        );
      } else {
        print('Failed to send drafts and images: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to call API: $error');
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
