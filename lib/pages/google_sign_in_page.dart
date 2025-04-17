import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import './main_menu_page.dart';
import '../services/auth_service.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  // Check if the user is logged in
  void _checkLoggedInStatus() async {
    String? accessToken = await _storage.read(key: 'accessToken');
    if (accessToken != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => MainMenuPage()));
    }
  }

  // Sign in with Google
Future<void> _signInWithGoogle() async {
  try {
    // Start Google Sign-In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // User cancelled login

    // Get Google Sign-In authentication
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Send the access token to backend for validation and processing
// Send the access token to backend for validation and processing
final response = await http.post(
  Uri.parse('${Constants.backendUrl}/auth/google'),
  body: json.encode({
    'access_token': googleAuth.accessToken,
  }),
  headers: {'Content-Type': 'application/json'},
);

  if (response.statusCode == 200) {
    // Parse the response and save tokens
    final responseData = json.decode(response.body);
    String accessToken = responseData['accessToken'];
    String refreshToken = responseData['refreshToken'];

    // Securely store the tokens
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);

    // Navigate to Main Menu
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => MainMenuPage()));
  } else if (response.statusCode == 404) {
    print('User not found. Logging out.');
      setState(() {
    _errorMessage = 'User not found. Please contact support.';
  });
    _authService.logout(context,timeout: true); // Trigger logout if user not found
  } else {
    print('Unexpected error: ${response.statusCode}');
  }

    } catch (e) {
      print("Error during Google sign-in: $e");
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Google Sign-In')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _signInWithGoogle,
            child: Text('Sign in with Google'),
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ]
        ],
      ),
    ),
  );
}

}

