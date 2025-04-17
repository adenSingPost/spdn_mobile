import 'package:flutter/material.dart';
import 'misdelivery_page.dart';
import 'masterdoor_page.dart';
import 'return_mailbox_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './main_menu_page.dart';
import '../services/qc/submit.dart'; // Import the DraftService
import '../services/auth_service.dart'; // Import the AuthService

class QCMainMenu extends StatefulWidget {
  final String postalCode;
  final String buildingNumber;
  final int nest;

  QCMainMenu({required this.postalCode, required this.buildingNumber, required this.nest});

  @override
  _QCMainMenuState createState() => _QCMainMenuState();
}

class _QCMainMenuState extends State<QCMainMenu> {
  bool misdeliveryDone = false;
  bool masterdoorDone = false;
  bool returnMailboxDone = false;

  // Create instances of AuthService and DraftService
  final AuthService _authService = AuthService();
  late final DraftService _draftService;

  @override
  void initState() {
    super.initState();
    // Initialize DraftService with AuthService
    _draftService = DraftService(_authService);
  }

  void _updateFormStatus(String formType, bool isCompleted) {
    setState(() {
      if (formType == "misdelivery") misdeliveryDone = isCompleted;
      if (formType == "masterdoor") masterdoorDone = isCompleted;
      if (formType == "returnMailbox") returnMailboxDone = isCompleted;
    });
  }

  bool get isAllCompleted => misdeliveryDone && masterdoorDone && returnMailboxDone;

  // _submitAll method to call sendAllDraftsToBackend
  Future<void> _submitAll(BuildContext context) async {
    // Call sendAllDraftsToBackend to submit drafts to the backend
    await _draftService.sendAllDraftsToBackend(context, widget.postalCode, widget.nest); 

    // You can show a confirmation message after submitting drafts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All drafts submitted successfully!')),
    );
  }
  Future<void> _clearAllDraft(BuildContext context) async {
    // Call sendAllDraftsToBackend to submit drafts to the backend
    await _draftService.clearAllDraft(context); 

    // You can show a confirmation message after submitting drafts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All drafts submitted successfully!')),
    );
  }

Future<bool> _onWillPop() async {
  // Show confirmation dialog and return true or false based on user input
  bool shouldPop = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Clear all drafts?'),
      content: Text('Are you sure you want to leave without submitting your drafts?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);  // User clicked No
          },
          child: Text('No'),
        ),
        TextButton(
          onPressed: () async {
            // Clear all drafts when the user confirms
            await _draftService.clearAllDraft(context);  // Call your function to clear drafts
            Navigator.of(context).pop(true);  // User clicked Yes, proceed with the pop
          },
          child: Text('Yes'),
        ),
      ],
    ),
  ) ?? false; // Default to false if dialog is dismissed

  return shouldPop; // Return true/false based on user's decision
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QC Job Checklist'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            bool shouldPop = await _onWillPop(); // Wait for the dialog result
            if (shouldPop) {
              Navigator.pop(context); // If confirmed, pop the screen
            }
          },
        ),
      ),
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
            onPressed: isAllCompleted ? () => _submitAll(context) : null,
            child: Text('Submit All'),
          ),
        ],
      ),
    );
  }
}
