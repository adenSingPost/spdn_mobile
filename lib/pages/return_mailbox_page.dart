import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class ReturnMailboxChecklist extends StatefulWidget {
  final String postalCode;
  final String buildingNumber;
  final Function(bool) onSave;

  const ReturnMailboxChecklist({
    Key? key,
    required this.postalCode,
    required this.buildingNumber,
    required this.onSave,
  }) : super(key: key);

  @override
  _ReturnMailboxChecklistState createState() => _ReturnMailboxChecklistState();
}

class _ReturnMailboxChecklistState extends State<ReturnMailboxChecklist> {
  int? _returnMailboxStatus;
  TextEditingController _observationsController = TextEditingController();
  bool _noReturnMailbox = false;
  List<String> _photoPaths = []; // Stores multiple photos
  bool _formCompleted = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  /// Load saved draft from local storage
  Future<void> _loadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('return_mailbox_draft');

    if (savedData != null) {
      Map<String, dynamic> draft = json.decode(savedData);
      setState(() {
        _returnMailboxStatus = draft['returnMailboxStatus'];
        _observationsController.text = draft['observations'] ?? '';
        _photoPaths = List<String>.from(draft['photoPaths'] ?? []);
        _noReturnMailbox = draft['noReturnMailbox'] ?? false;
      });
    }
  }

  /// Save draft to local storage
  Future<void> _saveDraft() async {
    if (_returnMailboxStatus == null && !_noReturnMailbox) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select either 'Return Mailbox Cleared', 'Return Mailbox Not Cleared', or check 'No return mailbox' before saving.",
          ),
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> draftData = {
      'postalCode': widget.postalCode,
      'buildingNumber': widget.buildingNumber,
      'returnMailboxStatus': _returnMailboxStatus,
      'observations': _observationsController.text,
      'photoPaths': _photoPaths, // Save multiple photos
      'noReturnMailbox': _noReturnMailbox,
    };

    await prefs.setString('return_mailbox_draft', json.encode(draftData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draft saved successfully!")),
    );
  }

void _saveForm() async {
  // Ensure either 'No return mailbox' is checked, or one of the return mailbox status options is selected
  if (!_noReturnMailbox && _returnMailboxStatus == null) {
    // If neither is selected, show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please select either 'Return Mailbox Cleared', 'Return Mailbox Not Cleared', or check 'No return mailbox' before saving.",
        ),
      ),
    );
    
    // Clear the observations and photos if no return mailbox is selected
    setState(() {
      _observationsController.clear();  // Clear observations
      _photoPaths.clear();  // Clear photos
    });

    return;
  }

  // Save draft to SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Map<String, dynamic> draftData = {
    'postalCode': widget.postalCode,
    'buildingNumber': widget.buildingNumber,
    'returnMailboxStatus': _returnMailboxStatus,
    'observations': _observationsController.text,
    'photoPaths': _photoPaths, // Save multiple photos
    'noReturnMailbox': _noReturnMailbox,
  };

  await prefs.setString('return_mailbox_draft', json.encode(draftData));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Draft saved successfully!")),
  );

  // Mark form as completed and call the callback
  setState(() => _formCompleted = true);
  widget.onSave(true);

  // Close the screen after saving
  Navigator.pop(context);
}


  /// Pick a photo from the gallery or camera
  Future<void> _pickPhoto(ImageSource source) async {
    if (_photoPaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can upload a maximum of 5 photos.")),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() {
        _photoPaths.add(photo.path);
      });
    }
  }

  /// Remove a photo
  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  /// Handle radio button selection logic
  void _onRadioChanged(int? value) {
    setState(() {
      _returnMailboxStatus = value;
      if (value != null) {
        _noReturnMailbox = false; // Uncheck "No return mailbox" when selecting a radio button
      }
    });
  }

  /// Handle "No return mailbox" checkbox logic
  void _onNoReturnMailboxChanged(bool? value) {
    setState(() {
      _noReturnMailbox = value ?? false;
      if (_noReturnMailbox) {
        _returnMailboxStatus = null; // Clear the return mailbox status when "No return mailbox" is checked
        _photoPaths.clear(); // Clear all photos when "No return mailbox" is checked
      }
    });
  }



@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Return Mailbox Checklist")),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display postal code & building number
          Text(
            "Postal Code: ${widget.postalCode}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            "Building Number: ${widget.buildingNumber}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Return Mailbox Checklist
          const Text(
            "Return Mailbox Checklist",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Radio buttons for mailbox status (disabled if "No return mailbox" is checked)
          RadioListTile<int>(
            title: const Text("Return Mailbox Cleared"),
            value: 1,
            groupValue: _returnMailboxStatus,
            onChanged: _noReturnMailbox ? null : _onRadioChanged, // Disable when noReturnMailbox is checked
          ),
          RadioListTile<int>(
            title: const Text("Return Mailbox Not Cleared"),
            value: 2,
            groupValue: _returnMailboxStatus,
            onChanged: _noReturnMailbox ? null : _onRadioChanged, // Disable when noReturnMailbox is checked
          ),
          const SizedBox(height: 10),

          // Observations text input (disabled if "No return mailbox" is checked)
          TextField(
            controller: _observationsController,
            decoration: const InputDecoration(labelText: "Type observations"),
            enabled: !_noReturnMailbox, // Disable if "No return mailbox" is checked
          ),
          const SizedBox(height: 10),

          // Upload photo section (disabled if "No return mailbox" is checked)
          const Text(
            "Upload Photos (Max: 5)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _noReturnMailbox ? null : () => _pickPhoto(ImageSource.camera), // Disable when "No return mailbox" is checked
                child: const Text("Take Photo"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _noReturnMailbox ? null : () => _pickPhoto(ImageSource.gallery), // Disable when "No return mailbox" is checked
                child: const Text("Upload Photo"),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Display uploaded photos (disabled if "No return mailbox" is checked)
          Wrap(
            spacing: 8,
            children: _photoPaths.asMap().entries.map((entry) {
              int index = entry.key;
              String photoPath = entry.value;
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(
                    File(photoPath),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  GestureDetector(
                    onTap: _noReturnMailbox ? null : () => _removePhoto(index), // Disable removal when "No return mailbox" is checked
                    child: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Checkbox for "No return mailbox"
          CheckboxListTile(
            title: const Text("No return mailbox"),
            value: _noReturnMailbox,
            onChanged: _onNoReturnMailboxChanged,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 20),

          // Save as Draft button (enabled only when the form is not in the "No return mailbox" state)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _saveForm, // Disable when "No return mailbox" is checked
                child: const Text("Save as Draft"),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}