import 'package:flutter/material.dart';
import '../../services/postal_code_service.dart';
import 'qc_job_menu_page.dart';

class QCPostalEntryPage extends StatefulWidget {
  @override
  _QCPostalEntryPageState createState() => _QCPostalEntryPageState();
}

class _QCPostalEntryPageState extends State<QCPostalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController postalCodeController = TextEditingController();
  String buildingNumber = '';

  void _fetchBuildingNumber() async {
    String postalCode = postalCodeController.text;
    if (postalCode.length == 6) {
      String result = await PostalCodeService.fetchBuildingNumber(postalCode);
      setState(() {
        buildingNumber = result;
      });
    }
  }

  void _navigateToQCMenu() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QCJobMenuPage(
            postalCode: postalCodeController.text,
            buildingNumber: buildingNumber,
          ),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: postalCodeController,
                decoration: InputDecoration(labelText: 'Postal Code'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 6) {
                    return 'Enter a valid 6-digit postal code';
                  }
                  return null;
                },
                onChanged: (value) => _fetchBuildingNumber(),
              ),
              SizedBox(height: 10),
              Text('Building Number: $buildingNumber'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToQCMenu,
                child: Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
