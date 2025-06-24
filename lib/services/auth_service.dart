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

    if (storedAccessToken != null && !JwtDecoder.isExpired(storedAccessToken)) {
      return storedAccessToken; // Token is still valid
    }

    // Access token is expired, attempt to refresh it
    String? storedRefreshToken = await _storage.read(key: 'refreshToken');
    if (storedRefreshToken == null) {
      await _clearTokens();  // Clear both tokens
      _redirectToSignIn(context);  // Redirect to Google Sign-In page
      return null;
    }
  
    try {
      final response = await http.post(
        Uri.parse('${Constants.middlewareUrl}/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-ID': Constants.appId,
          'X-API-Key': Constants.apiKey,
        },
        body: jsonEncode({'refreshToken': storedRefreshToken}),
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
        return null;
      }
    } catch (error) {
      return null;
    }
  }

  // Log out the user by deleting tokens and user data
  Future<void> _clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'user');
  }

  // Redirect to Google Sign-In page
  void _redirectToSignIn(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GoogleSignInPage()),
    );
  }

  // Logout function to clear tokens and redirect to sign-in page
  Future<void> logout(BuildContext context, {bool timeout = false}) async {
    try {
      // Clear all stored data
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');
      await _storage.delete(key: 'user');

      // Verify tokens are actually cleared
      String? accessToken = await _storage.read(key: 'accessToken');
      String? refreshToken = await _storage.read(key: 'refreshToken');
      String? userData = await _storage.read(key: 'user');
      
      if (timeout) {
        await Future.delayed(Duration(milliseconds: 3000));
      }

      // Force a complete app restart by navigating to sign-in with replacement
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => GoogleSignInPage()),
          (route) => false, // Remove all previous routes
        );
      }
      
    } catch (error) {
      // Even if there's an error, try to redirect to sign-in
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => GoogleSignInPage()),
          (route) => false, // Remove all previous routes
        );
      }
    }
  }
}
