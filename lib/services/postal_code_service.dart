import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/auth_service.dart';
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
      // First, check user access
      final authService = AuthService();
      String? accessToken = await authService.getValidAccessToken(context);
      
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Authentication required',
          'hasAccess': false,
          'buildingNumber': null
        };
      }

      // Check access with backend

      final accessResponse = await http.post(
        Uri.parse('${Constants.backendUrl}/region/check-access'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'postal_code': postalCode,
          'email': userEmail,
        }),
      );

      print('Access check response status: ${accessResponse.statusCode}');
      print('Access check response body: ${accessResponse.body}');

      if (accessResponse.statusCode == 200) {
        final accessData = jsonDecode(accessResponse.body);
        
        if (accessData['success'] == true && accessData['data']['has_access'] == true) {
          // User has access, now fetch building number
          final buildingNumber = await fetchBuildingNumber(postalCode);
          
          return {
            'success': true,
            'message': 'Access granted',
            'hasAccess': true,
            'buildingNumber': buildingNumber,
            'userData': accessData['data']['user'],
            'subbaseData': accessData['data']['subbase']
          };
        } else {
          return {
            'success': false,
            'message': accessData['message'] ?? 'Access denied',
            'hasAccess': false,
            'buildingNumber': null
          };
        }
      } else if (accessResponse.statusCode == 403) {
        final accessData = jsonDecode(accessResponse.body);
        return {
          'success': false,
          'message': accessData['message'] ?? 'Access denied',
          'hasAccess': false,
          'buildingNumber': null
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check access',
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
