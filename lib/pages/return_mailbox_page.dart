import 'package:flutter/material.dart';

class ReturnMailboxPage extends StatelessWidget {
  final String postalCode;
  final String buildingNumber;

  ReturnMailboxPage({required this.postalCode, required this.buildingNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Return Mailbox Form')),
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
