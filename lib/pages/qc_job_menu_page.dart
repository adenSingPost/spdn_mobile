import 'package:flutter/material.dart';
import 'misdelivery_page.dart';
import 'masterdoor_page.dart';
import 'return_mailbox_page.dart';

class QCJobMenuPage extends StatelessWidget {
  final String postalCode;
  final String buildingNumber;

  QCJobMenuPage({required this.postalCode, required this.buildingNumber});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QC Job Menu')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Postal Code: $postalCode'),
            Text('Building Number: $buildingNumber'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateTo(context, MisdeliveryPage(postalCode: postalCode, buildingNumber: buildingNumber)),
              child: Text('Misdelivery'),
            ),
            ElevatedButton(
              onPressed: () => _navigateTo(context, MasterdoorPage(postalCode: postalCode, buildingNumber: buildingNumber)),
              child: Text('Masterdoor'),
            ),
            ElevatedButton(
              onPressed: () => _navigateTo(context, ReturnMailboxPage(postalCode: postalCode, buildingNumber: buildingNumber)),
              child: Text('Return Mailbox'),
            ),
          ],
        ),
      ),
    );
  }
}
