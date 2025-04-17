// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../utils/constants.dart';
// import '../../services/auth_service.dart';
// import 'package:flutter/material.dart';

// class MisdeliveryService {
//   final AuthService _authService;

//   MisdeliveryService(this._authService);

//   // Call Protected API
//   Future<String> callProtectedApi(BuildContext context) async {
//     String? validAccessToken = await _authService.getValidAccessToken(context);

//     if (validAccessToken == null) {
//       return 'Authentication error. Please log in again.';
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('${Constants.backendUrl}/protected/test'),
//         headers: {
//           'Authorization': 'Bearer $validAccessToken',
//         },
//       );

//       if (response.statusCode == 200) {
//         return json.decode(response.body).toString();
//       } else {
//         return 'Error: ${response.statusCode} - ${response.body}';
//       }
//     } catch (error) {
//       return 'Failed to call API: $error';
//     }
//   }
// }
