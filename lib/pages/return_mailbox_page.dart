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
      });
    }
  }

  /// Save draft to local storage
  Future<void> _saveDraft() async {
    if (_returnMailboxStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a return mailbox status before saving.",
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
      'photoPaths': _photoPaths,
    };

    await prefs.setString('return_mailbox_draft', json.encode(draftData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draft saved successfully!")),
    );
  }

  void _saveForm() async {
    if (_returnMailboxStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a return mailbox status before saving.",
          ),
        ),
      );
      return;
    }

    await _saveDraft();
    setState(() => _formCompleted = true);
    widget.onSave(true);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Return Mailbox Checklist")),
      body: SingleChildScrollView(
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

            // Radio buttons for mailbox status
            RadioListTile<int>(
              title: const Text("No return mailbox"),
              value: 0,
              groupValue: _returnMailboxStatus,
              onChanged: _onRadioChanged,
            ),
            RadioListTile<int>(
              title: const Text("Return Mailbox Cleared"),
              value: 1,
              groupValue: _returnMailboxStatus,
              onChanged: _onRadioChanged,
            ),
            RadioListTile<int>(
              title: const Text("Return Mailbox Not Cleared"),
              value: 2,
              groupValue: _returnMailboxStatus,
              onChanged: _onRadioChanged,
            ),
            const SizedBox(height: 10),

            // Observations text input
            TextField(
              controller: _observationsController,
              decoration: const InputDecoration(labelText: "Type observations"),
            ),
            const SizedBox(height: 10),

            // Upload photo section
            const Text(
              "Upload Photos (Max: 5)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  child: const Text("Take Photo"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  child: const Text("Upload Photo"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Display uploaded photos
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
                      onTap: () => _removePhoto(index),
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

            // Save as Draft button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _saveForm,
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