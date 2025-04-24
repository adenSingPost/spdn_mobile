import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/misdelivery.dart';
import '../models/masterdoor.dart';
import '../models/return_mailbox.dart';
import './auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
        },
        body: jsonEncode(rows),
      );

      if (response.statusCode != 200) {
        print('Failed to update misdeliveries: ${response.body}');
        return false;
      }
      
      print('Successfully updated all misdelivery transactions');
      return true;
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

      // Add text fields
      request.fields['checklist_option'] = checklistOption.toString();
      request.fields['observation'] = observation;

      // Add images if any
      if (photoPaths.isNotEmpty) {
        for (var i = 0; i < photoPaths.length; i++) {
          final imageFile = File(photoPaths[i]);
          final newFilename = generateNewFilename(
            'master_door_draft',
            transaction.postalCode,
            imageFile,
            i + 1
          );
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              photoPaths[i],
              filename: newFilename,
            ),
          );
        }
      }

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        print('Successfully updated masterdoor record');
        return true;
      } else {
        print('Failed to update masterdoor: ${jsonResponse['message']}');
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

      // Add text fields
      request.fields['checklist_option'] = checklistOption.toString();
      request.fields['observation'] = observation;

      // Add images if any
      if (photoPaths.isNotEmpty) {
        for (var i = 0; i < photoPaths.length; i++) {
          final imageFile = File(photoPaths[i]);
          final newFilename = generateNewFilename(
            'return_mailbox_draft',
            transaction.postalCode,
            imageFile,
            i + 1
          );
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              photoPaths[i],
              filename: newFilename,
            ),
          );
        }
      }

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        print('Successfully updated return mailbox record');
        return true;
      } else {
        print('Failed to update return mailbox: ${jsonResponse['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating return mailbox: $e');
      return false;
    }
  }
} 