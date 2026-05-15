import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class PostalCodeService {
  static Future<Map<String, dynamic>> checkAccessAndFetchBuildingNumber(
    String postalCode, 
    String userEmail,
    BuildContext context
  ) async {
    if (postalCode.length != 6) {
      return {
        'success': false,
        'message': 'Invalid postal code format',
        'hasAccess': false,
        'buildingNumber': null
      };
    }

    try {
      // Mock access check - always return success
      print('Mock access check for postal code: $postalCode, email: $userEmail');
      
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 500));
      
      // Mock successful access response
      final mockAccessData = <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'has_access': true,
          'user': <String, dynamic>{
            'id': 1,
            'email': userEmail,
            'name': 'Test User'
          },
          'subbase': <String, dynamic>{
            'subbase_code': 'TEST001',
            'subbase_name': 'Test Subbase'
          }
        }
      };
      
      if (mockAccessData['success'] == true && mockAccessData['data']?['has_access'] == true) {
        // User has access, now fetch building number
        final buildingNumber = await fetchBuildingNumber(postalCode);
        
        return {
          'success': true,
          'message': 'Access granted',
          'hasAccess': true,
          'buildingNumber': buildingNumber,
          'userData': mockAccessData['data']?['user'],
          'subbaseData': mockAccessData['data']?['subbase']
        };
      } else {
        return {
          'success': false,
          'message': 'Access denied',
          'hasAccess': false,
          'buildingNumber': null
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking access: $e',
        'hasAccess': false,
        'buildingNumber': null
      };
    }
  }

  static Future<String?> fetchBuildingNumber(String postalCode) async {
    if (postalCode.length != 6) {
      return null;
    }

    var url = Uri.parse('https://www.sglocate.com/api/json/searchwithpostcode.aspx');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'APIKey': '394A6F696E304AE2AD1FE6AE92B6DF33B1FF166FAAD74903BCB2DE7180955402',
        'APISecret': 'D212808035CB4E3BA6BA807790E5F4F28248E8AB6CFD4EC68B6B3917318A2EAB',
        'Postcode': postalCode,
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['IsSuccess'] == true && data['Postcodes'] != null && data['Postcodes'].isNotEmpty) {
        return data['Postcodes'][0]['BuildingNumber'] ?? null;
      }
      return null;
    }
    return null;
  }
}
