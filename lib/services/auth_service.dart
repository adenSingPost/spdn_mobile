import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';  // For decoding JWT token
import '../utils/constants.dart';
import 'package:flutter/material.dart'; // For Navigator
import '../pages/google_sign_in_page.dart';
import 'package:url_launcher/url_launcher.dart';

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
      print('Refreshing access token...');
      final response = await http.post(
        Uri.parse('${Constants.middlewareUrl}/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refreshToken': storedRefreshToken}),
      );

      print('Refresh response status: ${response.statusCode}');
      print('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String newAccessToken = responseData['accessToken'];
        String newRefreshToken = responseData['refreshToken'];
        Map<String, dynamic> userData = responseData['user'];

        // Save new tokens and user data
        await _storage.write(key: 'accessToken', value: newAccessToken);
        await _storage.write(key: 'refreshToken', value: newRefreshToken);
        await _storage.write(key: 'user', value: jsonEncode(userData));

        print('Tokens refreshed successfully');
        return newAccessToken;
      } else {
        print('Token refresh failed with status: ${response.statusCode}');
        await _clearTokens();  // Clear both tokens
        _redirectToSignIn(context);  // Redirect to Google Sign-In page
        return null;
      }
    } catch (error) {
      print('Error refreshing token: $error');
      await _clearTokens();  // Clear both tokens
      _redirectToSignIn(context);  // Redirect to Google Sign-In page
      return null;
    }
  }

  // Method to manually refresh tokens
  Future<bool> refreshTokens(BuildContext context) async {
    String? storedRefreshToken = await _storage.read(key: 'refreshToken');
    if (storedRefreshToken == null) {
      await _clearTokens();
      _redirectToSignIn(context);
      return false;
    }

    try {
      print('Manually refreshing tokens...');
      final response = await http.post(
        Uri.parse('${Constants.backendUrl}/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refreshToken': storedRefreshToken}),
      );

      print('Manual refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String newAccessToken = responseData['accessToken'];
        String newRefreshToken = responseData['refreshToken'];
        Map<String, dynamic> userData = responseData['user'];

        // Save new tokens and user data
        await _storage.write(key: 'accessToken', value: newAccessToken);
        await _storage.write(key: 'refreshToken', value: newRefreshToken);
        await _storage.write(key: 'user', value: jsonEncode(userData));

        print('Manual token refresh successful');
        return true;
      } else {
        print('Manual token refresh failed with status: ${response.statusCode}');
        await _clearTokens();
        _redirectToSignIn(context);
        return false;
      }
    } catch (error) {
      print('Error during manual token refresh: $error');
      await _clearTokens();
      _redirectToSignIn(context);
      return false;
    }
  }

  // Method to check if tokens need refresh
  Future<bool> needsTokenRefresh() async {
    String? accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null) return true;
    
    return JwtDecoder.isExpired(accessToken);
  }

  // Log out the user by deleting tokens and user data
  Future<void> _clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'user');
    await _storage.delete(key: 'appId');
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
      await _storage.delete(key: 'appId');

      // Verify tokens are actually cleared
      String? accessToken = await _storage.read(key: 'accessToken');
      String? refreshToken = await _storage.read(key: 'refreshToken');
      String? userData = await _storage.read(key: 'user');
      String? appId = await _storage.read(key: 'appId');
      
      print('Logout verification - accessToken: ${accessToken != null ? 'present' : 'cleared'}');
      print('Logout verification - refreshToken: ${refreshToken != null ? 'present' : 'cleared'}');
      print('Logout verification - user: ${userData != null ? 'present' : 'cleared'}');
      print('Logout verification - appId: ${appId != null ? 'present' : 'cleared'}');
      
      // Clear query parameters if they exist
      await _clearQueryParams();
      
      if (timeout) {
        await Future.delayed(Duration(milliseconds: 3000));
      }

      // Force a complete app restart by navigating to sign-in with replacement
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => GoogleSignInPage(isFromLogout: true)),
          (route) => false, // Remove all previous routes
        );
      }
      
    } catch (error) {
      print('Error during logout: $error');
      // Even if there's an error, try to redirect to sign-in
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => GoogleSignInPage(isFromLogout: true)),
          (route) => false, // Remove all previous routes
        );
      }
    }
  }

  // Method to clear query parameters by redirecting to clean URL
  Future<void> _clearQueryParams() async {
    try {
      // For Flutter apps, we can't directly clear URL parameters
      // But we can ensure the app starts fresh by forcing a restart
      print('Clearing query parameters - forcing app restart');
      
      // The navigation to GoogleSignInPage with pushAndRemoveUntil 
      // will ensure a clean state without query parameters
    } catch (e) {
      print('Error clearing query params: $e');
    }
  }
}
