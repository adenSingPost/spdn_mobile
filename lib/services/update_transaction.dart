import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/misdelivery.dart';
import '../models/masterdoor.dart';
import '../models/return_mailbox.dart';
import './auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

class UpdateTransactionService {
  static String generateNewFilename(String draftKey, String postalCode, File imageFile, int index) {
    // Get current date and format it as ddMMyyHHmm (date + hour + minute)
    final now = DateTime.now();
    final formattedDate = DateFormat('ddMMyyHHmm').format(now); 

    // Get the file extension (e.g., jpg, png)
    final extension = imageFile.uri.pathSegments.last.split('.').last;

    // Generate the new filename with draftKey, postalCode, date, and index
    return '$draftKey-$postalCode-$formattedDate-$index.$extension';
  }

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

  static Future<bool> updateMisdelivery(BuildContext context, MisdeliveryTransaction transaction, List<Map<String, dynamic>> inputs) async {
    final AuthService _authService = AuthService();
    String? validAccessToken = await _authService.getValidAccessToken(context);
    
    if (validAccessToken == null) {
      print('No access token available');
      return false;
    }

    // Debug log the inputs
    print('DEBUG: UpdateTransactionService - Received inputs:');
    for (var input in inputs) {
      print('DEBUG:   Input ID: ${input['id']} (${input['id']?.runtimeType})');
      print('DEBUG:   Input data: $input');
    }

    // Prepare the array of rows
    final List<Map<String, dynamic>> rows = inputs.map((input) {
      final int? id = input['id'];
      if (id == null) {
        print('DEBUG: Skipping input with null ID');
        return null;
      }
      
      return {
        'id': id,
        'isPostalCode': input['isPostalCode'],
        'foundAt': input['foundAt'],
        'meantFor': input['meantFor'],
      };
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
    
    print('DEBUG: Prepared rows data: $rows');

    try {
      final response = await http.put(
        Uri.parse('${Constants.backendUrl}/edit_draft/misdelivery/${transaction.mainDraftId}'),
        headers: {
          'Authorization': 'Bearer $validAccessToken',
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=60, max=1000',
        },
        body: jsonEncode(rows),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          print('Successfully updated all misdelivery transactions');
          return true;
        } else {
          print('Failed to update misdeliveries: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('Failed to update misdeliveries: Status code ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating misdeliveries: $e');
      return false;
    }
  }

  static Future<bool> updateMasterdoor(
    BuildContext context,
    MasterdoorTransaction transaction,
    int checklistOption,
    String observation,
    List<String> photoPaths,
  ) async {
    final AuthService _authService = AuthService();
    String? validAccessToken = await _authService.getValidAccessToken(context);
    
    if (validAccessToken == null) {
      print('No access token available');
      return false;
    }

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${Constants.backendUrl}/edit_draft/masterdoor/${transaction.id}'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $validAccessToken';
      request.headers['Connection'] = 'keep-alive';
      request.headers['Keep-Alive'] = 'timeout=60, max=1000';

      // Add text fields
      request.fields['checklist_option'] = checklistOption.toString();
      request.fields['observation'] = observation;

      // Add images if any
      if (photoPaths.isNotEmpty) {
        // Compress all images in parallel first
        List<File> compressedImages = await Future.wait(
          photoPaths.map((path) => compressImage(File(path)))
        );

        // Add all compressed images to request
        for (var i = 0; i < compressedImages.length; i++) {
          final compressedFile = compressedImages[i];
          final newFilename = generateNewFilename(
            'master_door_draft',
            transaction.postalCode,
            compressedFile,
            i + 1
          );
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              compressedFile.path,
              filename: newFilename,
            ),
          );
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
          print('Successfully updated masterdoor record');
          return true;
        } else {
          print('Failed to update masterdoor: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('Failed to update masterdoor: Status code ${response.statusCode}');
        print('Response body: $responseBody');
        return false;
      }
    } catch (e) {
      print('Error updating masterdoor: $e');
      return false;
    }
  }

  static Future<bool> updateReturnMailbox(
    BuildContext context,
    ReturnMailboxTransaction transaction,
    int checklistOption,
    String observation,
    List<String> photoPaths,
  ) async {
    final AuthService _authService = AuthService();
    String? validAccessToken = await _authService.getValidAccessToken(context);
    
    if (validAccessToken == null) {
      print('No access token available');
      return false;
    }

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${Constants.backendUrl}/edit_draft/returnmailbox/${transaction.id}'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $validAccessToken';
      request.headers['Connection'] = 'keep-alive';
      request.headers['Keep-Alive'] = 'timeout=60, max=1000';

      // Add text fields
      request.fields['checklist_option'] = checklistOption.toString();
      request.fields['observation'] = observation;

      // Add images if any
      if (photoPaths.isNotEmpty) {
        // Compress all images in parallel first
        List<File> compressedImages = await Future.wait(
          photoPaths.map((path) => compressImage(File(path)))
        );

        // Add all compressed images to request
        for (var i = 0; i < compressedImages.length; i++) {
          final compressedFile = compressedImages[i];
          final newFilename = generateNewFilename(
            'return_mailbox_draft',
            transaction.postalCode,
            compressedFile,
            i + 1
          );
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              compressedFile.path,
              filename: newFilename,
            ),
          );
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
          print('Successfully updated return mailbox record');
          return true;
        } else {
          print('Failed to update return mailbox: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('Failed to update return mailbox: Status code ${response.statusCode}');
        print('Response body: $responseBody');
        return false;
      }
    } catch (e) {
      print('Error updating return mailbox: $e');
      return false;
    }
  }
} 