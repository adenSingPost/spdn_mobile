import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './pages/google_sign_in_page.dart';
import './pages/main_menu_page.dart';

void main() async {
  // Ensure that WidgetsFlutterBinding is initialized before calling any async code
  WidgetsFlutterBinding.ensureInitialized();

  // Create an instance of FlutterSecureStorage to read from storage
  final storage = FlutterSecureStorage();

  // Check if the user has a stored access token
  String? accessToken = await storage.read(key: 'accessToken');

  // Run the app and pass the initial route based on login status
  runApp(MyApp(isLoggedIn: accessToken != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPDN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Navigate to different screens based on login status
      home: _getHomePage(),
    );
  }

  // Method to return the correct home page based on login status
  Widget _getHomePage() {
    if (isLoggedIn) {
      return MainMenuPage();  // Logged in, go to main menu page
    } else {
      return GoogleSignInPage();  // Not logged in, go to sign-in page
    }
  }
}
