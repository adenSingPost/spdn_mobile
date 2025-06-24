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
  String? _errorMessage;
  final _authService = AuthService();
  final _storage = FlutterSecureStorage();
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  
  // Add controllers for email/password fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initDeepLinkListener() async {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleGoogleCallback(uri);
    }, onError: (err) {
      print('Error handling deep link: $err');
    });
  }

  Future<void> _handleGoogleCallback(Uri uri) async {
    try {
      // Handle both localhost and custom scheme callbacks
      bool isCallback = false;
      
      // Check for localhost callback
      if (uri.scheme == 'http' && uri.host == 'localhost' && 
          (uri.path == '/auth/callback' || uri.path == '/auth/google/callback')) {
        isCallback = true;
      }
      
      // Check for custom scheme callback
      if (uri.scheme == 'spdn' && uri.host == 'auth' && 
          (uri.path == '/callback' || uri.path == '/google/callback')) {
        isCallback = true;
      }
      
      if (isCallback) {
        final accessToken = uri.queryParameters['accessToken'];
        final refreshToken = uri.queryParameters['refreshToken'];
        final userData = uri.queryParameters['user'];

        if (accessToken != null && refreshToken != null) {
          // Store tokens securely
          await _storage.write(key: 'accessToken', value: accessToken);
          await _storage.write(key: 'refreshToken', value: refreshToken);
          if (userData != null) {
            await _storage.write(key: 'user', value: userData);
          }
          
          if (mounted) {
            // Navigate to main menu on success
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainMenuPage()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Authentication failed: Missing tokens';
          });
        }
      } else if (uri.path == '/auth/error' || (uri.scheme == 'spdn' && uri.path == '/auth/error')) {
        final errorMessage = uri.queryParameters['message'] ?? 'Authentication failed';
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error handling authentication: $e';
      });
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
    _errorMessage = '';
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

  Future<void> _signInWithGoogle() async {
    try {
      // Create state object with just appId
      final state = {
        'appId': Constants.appId
      };
      
      // Encode state as base64 to ensure it's URL safe
      final encodedState = base64Encode(utf8.encode(json.encode(state)));
      
      // Launch the Google OAuth URL with app_id and state parameters
      final url = '${Constants.googleAuthUrl}?app_id=${Constants.appId}&redirect_uri=${Uri.encodeComponent(Constants.googleCallbackUrl)}&state=$encodedState';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        setState(() {
          _errorMessage = 'Could not launch Google sign in';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during Google sign-in: $e';
      });
    }
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all fields';
        });
        return;
      }

      // Encrypt password with shared secret
      final encryptedPassword = _encryptWithAES(password);

      final response = await http.post(
        Uri.parse('${Constants.middlewareUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-ID': Constants.appId,
          'X-API-Key': Constants.apiKey,
        },
        body: json.encode({
          'email': email,
          'encryptedPassword': encryptedPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store tokens securely
        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        await _storage.write(key: 'user', value: json.encode(data['user']));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainMenuPage()),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['error'] ?? 'Sign in failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during sign in: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _encryptWithAES(String password) {
    try {
      // Use a simple XOR encryption with a fixed key
      // This is just for demonstration - in production use proper AES
      final passwordBytes = utf8.encode(password);
      final keyBytes = utf8.encode(Constants.secretKey);
      
      final encryptedBytes = List<int>.generate(
        passwordBytes.length,
        (i) => passwordBytes[i] ^ keyBytes[i % keyBytes.length],
      );
      
      return base64Encode(encryptedBytes);
    } catch (e) {
      print('Error in AES encryption: $e');
      return base64Encode(utf8.encode(password));
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
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // Placeholder for forgot password
                  child: Text('Forgot Password?'),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                child: _isLoading 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or continue with',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _signInWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Sign in with Google'),
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
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => SignUpPage()),
                      );
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

