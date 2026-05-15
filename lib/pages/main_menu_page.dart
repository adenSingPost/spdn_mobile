import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
// import 'package:spdn_mobile/pages/transaction_page.dart';
import '../services/auth_service.dart';
import '../pages/qc_postal_entry_page.dart';
// import '../pages/reporting_menu_page.dart';
import '../pages/transaction_page.dart';
import '../widgets/app_version_footer.dart';

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final AuthService _authService = AuthService();
  String? _userEmail;
  String? _userName; // Add state for user name

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = FlutterSecureStorage();
    final userData = await storage.read(key: 'user');
    print('Loading user data: $userData');
    
    if (userData != null) {
      try {
        // Decode URL-encoded string first
        final decodedUserData = Uri.decodeComponent(userData);
        print('Decoded URL: $decodedUserData');
        
        final user = json.decode(decodedUserData);
        print('Decoded user data: $user');
        print('User name: ${user['name']}');
        print('User email: ${user['email']}');
        
        setState(() {
          _userEmail = user['email'];
          _userName = user['name']; // Extract user name
        });
        
        print('State updated - userName: $_userName, userEmail: $_userEmail');
      } catch (e) {
        print('Error decoding user data: $e');
        // Handle JSON decode error
      }
    } else {
      print('No user data found in storage');
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
          // User welcome display
          if (_userName != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue.shade600, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $_userName!',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userEmail != null) ...[
                          SizedBox(height: 4),
                          Text(
                            _userEmail!,
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
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
          const AppVersionFooter(),
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
