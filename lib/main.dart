import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './pages/google_sign_in_page.dart';
import './pages/main_menu_page.dart';
void main() async {
  // Make sure binding is initialized before running the app
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
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Navigate to different screens based on login status
      home: isLoggedIn ? MainMenuPage() : GoogleSignInPage(),
    );
  }
}
