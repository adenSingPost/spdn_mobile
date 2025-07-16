import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../services/postal_code_service.dart';
import 'qc_job_menu_page.dart';

class EnterPostalPage extends StatefulWidget {
  @override
  _EnterPostalPageState createState() => _EnterPostalPageState();
}

class _EnterPostalPageState extends State<EnterPostalPage> {
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _nestController = TextEditingController();
  String? _buildingNumber;
  bool _loading = false;
  String? _userEmail; // Add user email state

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final storage = FlutterSecureStorage();
    final userData = await storage.read(key: 'user');
    
    if (userData != null) {
      try {
        final decodedUserData = Uri.decodeComponent(userData);
        final user = json.decode(decodedUserData);
        setState(() {
          _userEmail = user['email'];
        });
      } catch (e) {
        print('Error loading user email: $e');
      }
    }
  }

  Future<void> _fetchBuildingNumber() async {
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_postalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a postal code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_postalController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postal code must be 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    
    // Use the new access check method
    final result = await PostalCodeService.checkAccessAndFetchBuildingNumber(
      _postalController.text.trim(),
      _userEmail!,
      context
    );
    
    setState(() => _loading = false);

    if (result['success'] == true && result['hasAccess'] == true) {
      final buildingNumber = result['buildingNumber'];
      
      if (buildingNumber != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QCMainMenu(
              postalCode: _postalController.text,
              buildingNumber: buildingNumber,
              nest: _nestController.text.isEmpty ? 0 : int.parse(_nestController.text),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Building number not found for this postal code.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Access denied or invalid postal code.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Postal Code')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _postalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter Postal Code'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nestController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter Nest (Optional)'),
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _fetchBuildingNumber,
                    child: Text('Continue'),
                  ),
          ],
        ),
      ),
    );
  }
}
