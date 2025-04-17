import 'package:flutter/material.dart';
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

  Future<void> _fetchBuildingNumber() async {
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
    String? result = await PostalCodeService.fetchBuildingNumber(_postalController.text);
    setState(() {
      _buildingNumber = result;
      _loading = false;
    });

    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QCMainMenu(
            postalCode: _postalController.text,
            buildingNumber: result,
            nest: _nestController.text.isEmpty ? 0 : int.parse(_nestController.text),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid postal code. Please check and try again.'),
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
