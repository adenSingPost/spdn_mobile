import 'package:flutter/material.dart';
import './pages/google_sign_in_page.dart';
import './utils/constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GoogleSignInPage(),
    );
  }
}
