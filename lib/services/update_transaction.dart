import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/misdelivery.dart';
import './auth_service.dart';
import 'package:flutter/material.dart';

class UpdateTransactionService {
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
} 