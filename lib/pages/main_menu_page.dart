import 'package:flutter/material.dart';
import '../pages/google_sign_in_page.dart';
import '../services/auth_service.dart';
import '../pages/qc_postal_entry_page.dart';
// import '../pages/reporting_menu_page.dart';

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final AuthService _authService = AuthService();

  // Log out the user
  Future<void> _logout(BuildContext context) async {
    await _authService.logout(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GoogleSignInPage()),
    );
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton(context, "QC JOB", Icons.assignment, Colors.blue, EnterPostalPage()),
            SizedBox(height: 20),
            // _buildMenuButton(context, "REPORTING", Icons.bar_chart, Colors.green, ReportingMenuPage()),
          ],
        ),
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
