import 'package:flutter/material.dart';
import 'misdelivery_page.dart';
import 'masterdoor_page.dart';
import 'return_mailbox_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './main_menu_page.dart';
class QCMainMenu extends StatefulWidget {
  final String postalCode;
  final String buildingNumber;

  QCMainMenu({required this.postalCode, required this.buildingNumber});

  @override
  _QCMainMenuState createState() => _QCMainMenuState();
}

class _QCMainMenuState extends State<QCMainMenu> {
  bool misdeliveryDone = false;
  bool masterdoorDone = false;
  bool returnMailboxDone = false;

  void _updateFormStatus(String formType, bool isCompleted) {
    setState(() {
      if (formType == "misdelivery") misdeliveryDone = isCompleted;
      if (formType == "masterdoor") masterdoorDone = isCompleted;
      if (formType == "returnMailbox") returnMailboxDone = isCompleted;
    });
  }

  bool get isAllCompleted => misdeliveryDone && masterdoorDone && returnMailboxDone;
void _submitAll() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Retrieve and process drafts
  String? misdeliveryData = prefs.getString('misDeliveryDraft');
  String? returnMailboxData = prefs.getString('return_mailbox_draft');
  String? masterDoorData = prefs.getString('master_door_draft');

  // Process Misdelivery Draft
  if (misdeliveryData != null) {
    Map<String, dynamic> misdeliveryDraft = json.decode(misdeliveryData);
    print("\n=== Misdelivery Checklist ===");
    print("Misdelivery Draft: ${misdeliveryDraft['draft']}");
    print("No Misdelivery: ${misdeliveryDraft['noMisdeliveryFound']}");
    // Retrieve photo path if it exists in Misdelivery draft
    String misdeliveryPhotoPath = misdeliveryDraft['photoPaths'] ?? 'No Photo';
    print("Photo Path: $misdeliveryPhotoPath");
  } else {
    print("\nNo Misdelivery Draft Found.");
  }

  // Process Return Mailbox Draft
  if (returnMailboxData != null) {
    Map<String, dynamic> returnMailboxDraft = json.decode(returnMailboxData);
    print("\n=== Return Mailbox Checklist ===");
    print("Postal Code: ${returnMailboxDraft['postalCode']}");
    print("Building Number: ${returnMailboxDraft['buildingNumber']}");
    print("Return Mailbox Status: ${returnMailboxDraft['returnMailboxStatus']}");
    print("Observations: ${returnMailboxDraft['observations']}");

    // Check if photoPaths is a list and log all photo paths if it exists
    List<dynamic> returnMailboxPhotoPaths = returnMailboxDraft['photoPaths'] ?? [];
    if (returnMailboxPhotoPaths.isNotEmpty) {
      for (int i = 0; i < returnMailboxPhotoPaths.length; i++) {
        print("Photo Path ${i + 1}: ${returnMailboxPhotoPaths[i]}");
      }
    } else {
      print("No photos found.");
    }

    print("No Return Mailbox: ${returnMailboxDraft['noReturnMailbox']}");
  } else {
    print("\nNo Return Mailbox Draft Found.");
  }

  // Process Master Door Draft
  if (masterDoorData != null) {
    Map<String, dynamic> masterDoorDraft = json.decode(masterDoorData);
    print("\n=== Master Door Checklist ===");
    print("Postal Code: ${masterDoorDraft['postalCode']}");
    print("Building Number: ${masterDoorDraft['buildingNumber']}");
    print("Master Door Status: ${masterDoorDraft['masterDoorStatus']}");
    print("Observations: ${masterDoorDraft['observations']}");
    // Retrieve photo path if it exists in Master Door draft
    List<dynamic> masterDoorPhotoPath = masterDoorDraft['photoPaths']  ?? [];
    if (masterDoorPhotoPath.isNotEmpty) {
      for (int i = 0; i < masterDoorPhotoPath.length; i++) {
        print("Photo Path ${i + 1}: ${masterDoorPhotoPath[i]}");
      }
    } else {
      print("No photos found.");
    }
    print("Master Door in Good Condition: ${masterDoorDraft['masterDoorGoodCondition']}");
  } else {
    print("\nNo Master Door Draft Found.");
  }

  // Clear all stored drafts
  await prefs.remove('misDeliveryDraft');
  await prefs.remove('return_mailbox_draft');
  await prefs.remove('master_door_draft');

  print("\n=== Drafts Cleared ===");

  // Reset form status
  setState(() {
    misdeliveryDone = false;
    masterdoorDone = false;
    returnMailboxDone = false;
  });

  // Navigate back to Main Menu
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => MainMenuPage()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QC Job Checklist')),
      body: Column(
        children: [
          ListTile(
            title: Text('Misdelivery'),
            trailing: Icon(misdeliveryDone ? Icons.check_circle : Icons.edit),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MisdeliveryPage(
                postalCode: widget.postalCode,
                buildingNumber: widget.buildingNumber,
                onSave: (status) => _updateFormStatus("misdelivery", status),
              ),
            )),
          ),
          ListTile(
            title: Text('Masterdoor'),
            trailing: Icon(masterdoorDone ? Icons.check_circle : Icons.edit),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MasterDoorPage(
                postalCode: widget.postalCode,
                buildingNumber: widget.buildingNumber,
                onSave: (status) => _updateFormStatus("masterdoor", status),
              ),
            )),
          ),
          ListTile(
            title: Text('Return Mailbox'),
            trailing: Icon(returnMailboxDone ? Icons.check_circle : Icons.edit),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ReturnMailboxChecklist(
                postalCode: widget.postalCode,
                buildingNumber: widget.buildingNumber,
                onSave: (status) => _updateFormStatus("returnMailbox", status),
              ),
            )),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: isAllCompleted ? _submitAll : null,
            child: Text('Submit All'),
          ),
        ],
      ),
    );
  }
}
