import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../utils/constants.dart';
import './main_menu_page.dart';
import '../services/auth_service.dart';
import './sign_up_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google SSO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GoogleSignInPage(),
    );
  }
}

class GoogleSignInPage extends StatefulWidget {
  @override
  _GoogleSignInPageState createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  final _authService = AuthService();
  final _storage = FlutterSecureStorage();
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  
  bool _hasCheckedLoginStatus = false;

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinkListener() async {
    _appLinks = AppLinks();
    
    // Check for initial app launch URL
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        print('Initial app link: $initialUri');
        _handleGoogleCallback(initialUri);
      }
    } catch (e) {
      print('Error getting initial app link: $e');
    }
    
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      print('Received deep link: $uri');
      _handleGoogleCallback(uri);
    }, onError: (err) {
      print('Error handling deep link: $err');
    });
  }

  Future<void> _handleGoogleCallback(Uri uri) async {
    try {
      print('Handling callback for URI: $uri');
      print('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
      print('Query params: ${uri.queryParameters}');
      
      // Handle both localhost and custom scheme callbacks
      bool isCallback = false;
      
      // Check for localhost callback (including root path)
      if (uri.scheme == 'http' && uri.host == 'localhost' && 
          (uri.path == '/' || uri.path == '/auth/callback' || uri.path == '/auth/google/callback')) {
        isCallback = true;
        print('Matched localhost callback');
      }
      
      // Check for custom scheme callback (spdn://auth/callback)
      if (uri.scheme == 'spdn' && uri.host == 'auth' && 
          (uri.path == '/callback' || uri.path == '/google/callback')) {
        isCallback = true;
        print('Matched spdn callback');
      }
      
      print('Is callback: $isCallback');
      
      if (isCallback) {
        final success = uri.queryParameters['success'];
        final accessToken = uri.queryParameters['accessToken'];
        final refreshToken = uri.queryParameters['refreshToken'];
        final userData = uri.queryParameters['user'];
        final appId = uri.queryParameters['appId'];

        print('Success: $success, AccessToken: ${accessToken != null ? 'present' : 'missing'}, RefreshToken: ${refreshToken != null ? 'present' : 'missing'}');

        // Check if authentication was successful
        if (success == 'true' && accessToken != null && refreshToken != null) {
          print('Authentication successful, storing tokens...');
          // Store tokens securely
          await _storage.write(key: 'accessToken', value: accessToken);
          await _storage.write(key: 'refreshToken', value: refreshToken);
          if (userData != null) {
            await _storage.write(key: 'user', value: userData);
          }
          if (appId != null) {
            await _storage.write(key: 'appId', value: appId);
          }
          
          print('Tokens stored, navigating to main menu...');
          if (mounted) {
            // Navigate to main menu on success
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainMenuPage()),
            );
          }
        } else {
          print('Authentication failed: success=$success, accessToken=${accessToken != null}, refreshToken=${refreshToken != null}');
        }
      } else if (uri.path == '/auth/error' || (uri.scheme == 'spdn' && uri.path == '/auth/error')) {
        final errorMessage = uri.queryParameters['message'] ?? 'Authentication failed';
      } else {
        print('URI did not match any callback pattern');
      }
    } catch (e) {
      print('Error in callback handler: $e');
    }
  }

  void _checkLoggedInStatus() async {
    if (_hasCheckedLoginStatus) {
      return;
    }
    
    String? accessToken = await _storage.read(key: 'accessToken');
    String? refreshToken = await _storage.read(key: 'refreshToken');
    String? userData = await _storage.read(key: 'user');
    
    if (accessToken != null && refreshToken != null) {
      _hasCheckedLoginStatus = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainMenuPage()),
      );
    } else {
      _hasCheckedLoginStatus = true;
    }
  }

  // Add a method to force refresh the login status
  void _forceRefreshLoginStatus() {
    _hasCheckedLoginStatus = false;
    _checkLoggedInStatus();
  }

  // Method to completely reset app state
  Future<void> _resetAppState() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'user');
    _hasCheckedLoginStatus = false;
  }

  // Method to completely restart the app
  Future<void> _restartApp() async {
    await _resetAppState();
    
    // Clear all navigation history and restart
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => GoogleSignInPage()),
      (route) => false,
    );
  }

  Future<void> _signInWithWeb() async {
    try {
      // Create state object with appId and callback URL
      final state = {
        'appId': Constants.appId,
        'callbackUrl': Constants.webCallbackUrl
      };
      
      // Encode state as base64 to ensure it's URL safe
      final encodedState = base64Encode(utf8.encode(json.encode(state)));
      
      // Launch the web auth URL with state parameter
      final url = '${Constants.webAuthUrl}?appid=${Constants.appId}&state=$encodedState';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Back'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signInWithWeb,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.web, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('SingPost One Login'),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 55),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

