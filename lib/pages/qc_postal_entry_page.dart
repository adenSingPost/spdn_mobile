import 'package:flutter/material.dart';
import '../../services/postal_code_service.dart';
import 'qc_job_menu_page.dart';
import 'package:flutter/material.dart';

class EnterPostalPage extends StatefulWidget {
  @override
  _EnterPostalPageState createState() => _EnterPostalPageState();
}

class _EnterPostalPageState extends State<EnterPostalPage> {
  final TextEditingController _postalController = TextEditingController();
  String? _buildingNumber;
  bool _loading = false;

  Future<void> _fetchBuildingNumber() async {
    setState(() => _loading = true);
    String? result = await PostalCodeService.fetchBuildingNumber(_postalController.text);
    setState(() {
      _buildingNumber = result;
      _loading = false;
    });

    if (_buildingNumber != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QCMainMenu(postalCode: _postalController.text, buildingNumber: _buildingNumber!),
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
            _loading ? CircularProgressIndicator() : ElevatedButton(
              onPressed: _fetchBuildingNumber,
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
