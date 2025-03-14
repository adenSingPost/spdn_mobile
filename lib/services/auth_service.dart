import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';  // For decoding JWT token
import '../utils/constants.dart';
import 'package:flutter/material.dart'; // For Navigator
import '../pages/google_sign_in_page.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Load stored tokens from secure storage
  Future<Map<String, String?>> loadTokens() async {
    String? accessToken = await _storage.read(key: 'accessToken');
    String? refreshToken = await _storage.read(key: 'refreshToken');

    return {'accessToken': accessToken, 'refreshToken': refreshToken};
  }

  // Function to check if access token is valid, refresh if expired
  Future<String?> getValidAccessToken(BuildContext context) async {
    String? storedAccessToken = await _storage.read(key: 'accessToken');
    
    if (storedAccessToken != null) {
      print('Token expired: ${JwtDecoder.isExpired(storedAccessToken)}');
    } else {
      print('No access token found');
    }

    if (storedAccessToken != null && !JwtDecoder.isExpired(storedAccessToken)) {
      return storedAccessToken; // Token is still valid
    }

    // Access token is expired, attempt to refresh it
    String? storedRefreshToken = await _storage.read(key: 'refreshToken');
    if (storedRefreshToken == null) {
      print('No refresh token found, user must log in again.');
      await _clearTokens();  // Clear both tokens
      _redirectToSignIn(context);  // Redirect to Google Sign-In page
      return null;
    }
  
    try {
      final response = await http.post(
        Uri.parse('${Constants.backendUrl}/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json', // Ensure JSON is sent
        },
        body: jsonEncode({'refreshToken': storedRefreshToken}), // Convert to JSON
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String newAccessToken = responseData['accessToken'];

        // Save new access token
        await _storage.write(key: 'accessToken', value: newAccessToken);

        return newAccessToken;
      } else {
      await _clearTokens();  // Clear both tokens
      _redirectToSignIn(context);  // Redirect to Google Sign-In page
        print('Failed to refresh access token: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Error refreshing access token: $error');
      return null;
    }
  }

  // Log out the user by deleting tokens
  Future<void> _clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  // Redirect to Google Sign-In page
  void _redirectToSignIn(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GoogleSignInPage()),
    );
  }

  // Logout function to clear tokens and redirect to sign-in page
  Future<void> logout(BuildContext context) async {
    await _clearTokens();  // Clear the tokens
    _redirectToSignIn(context);  // Redirect to the sign-in page
  }
}
