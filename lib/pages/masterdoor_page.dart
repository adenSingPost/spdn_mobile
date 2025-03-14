import 'package:flutter/material.dart';

class MasterdoorPage extends StatelessWidget {
  final String postalCode;
  final String buildingNumber;

  MasterdoorPage({required this.postalCode, required this.buildingNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Masterdoor Form')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Postal Code: $postalCode'),
            Text('Building Number: $buildingNumber'),
            SizedBox(height: 20),
            Text('Form content goes here...'),
          ],
        ),
      ),
    );
  }
}
