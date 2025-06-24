import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
// import 'package:spdn_mobile/pages/transaction_page.dart';
import '../pages/google_sign_in_page.dart';
import '../services/auth_service.dart';
import '../pages/qc_postal_entry_page.dart';
// import '../pages/reporting_menu_page.dart';
import '../pages/transaction_page.dart';

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final AuthService _authService = AuthService();
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = FlutterSecureStorage();
    final userData = await storage.read(key: 'user');
    if (userData != null) {
      try {
        final user = json.decode(userData);
        setState(() {
          _userEmail = user['email'];
        });
      } catch (e) {
        // Handle JSON decode error
      }
    }
  }

  // Log out the user
  Future<void> _logout(BuildContext context) async {
    await _authService.logout(context);
    // Don't do additional navigation - auth service handles it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Column(
        children: [
          // User email display
          if (_userEmail != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.grey.shade600, size: 16),
                  SizedBox(width: 8),
                  Text(
                    _userEmail!,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Main content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuButton(context, "QC JOB", Icons.assignment, Colors.blue, EnterPostalPage()),
                  SizedBox(height: 20),
                  _buildMenuButton(context, "TRANSACTIONS", Icons.receipt_long, Colors.deepPurple, TransactionsPage()),
                  SizedBox(height: 20),
                  // _buildMenuButton(context, "REPORTING", Icons.bar_chart, Colors.green, ReportingMenuPage()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(200, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }
}
