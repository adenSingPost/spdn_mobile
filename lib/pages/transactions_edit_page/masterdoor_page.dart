import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/masterdoor.dart';
import '../../services/update_transaction.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../../services/auth_service.dart';

class MasterDoorPage extends StatefulWidget {
  final MasterdoorTransaction transaction;
  final Function(bool) onSave;

  const MasterDoorPage({
    Key? key,
    required this.transaction,
    required this.onSave,
  }) : super(key: key);

  @override
  _MasterDoorPageState createState() => _MasterDoorPageState();
}

class _MasterDoorPageState extends State<MasterDoorPage> {
  int? _masterDoorStatus;
  TextEditingController _observationsController = TextEditingController();
  List<String> _photoPaths = []; // Store multiple photo paths
  bool _formCompleted = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize the form with transaction data
    _masterDoorStatus = widget.transaction.checklistOption;
    _observationsController.text = widget.transaction.observation ?? '';
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  /// Save the form and exit
  void _saveForm() async {
    if (_masterDoorStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a Masterdoor status before saving."),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Are you sure you want to update this masterdoor record?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    // If user cancelled, return
    if (confirmed != true) {
      return;
    }

    try {
      final success = await UpdateTransactionService.updateMasterdoor(
        context,
        widget.transaction,
        _masterDoorStatus!,
        _observationsController.text,
        _photoPaths,
      );

      if (success) {
        setState(() => _formCompleted = true);
        widget.onSave(true);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update masterdoor record"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating masterdoor: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Pick a photo from gallery or capture a new photo
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

  /// Remove a selected photo
  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  /// Handle radio button selection logic
  void _onRadioChanged(int? value) {
    setState(() {
      _masterDoorStatus = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Masterdoor Checklist")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display postal code & building number
              Text(
                "Postal Code: ${widget.transaction.postalCode}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Building Number: ${widget.transaction.buildingNumber}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Masterdoor Checklist
              const Text(
                "Masterdoor Checklist",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Radio buttons for masterdoor status
              Column(
                children: [
                  RadioListTile<int>(
                    title: const Text("Masterdoor is in Good Condition"),
                    value: 0,
                    groupValue: _masterDoorStatus,
                    onChanged: _onRadioChanged,
                  ),
                  RadioListTile<int>(
                    title: const Text("Masterdoor Faulty, Latch Loose"),
                    value: 1,
                    groupValue: _masterDoorStatus,
                    onChanged: _onRadioChanged,
                  ),
                  RadioListTile<int>(
                    title: const Text("Masterdoor Panel Not Aligned, Need to Adjust Hinge"),
                    value: 2,
                    groupValue: _masterDoorStatus,
                    onChanged: _onRadioChanged,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Observations text input
              TextField(
                controller: _observationsController,
                decoration: const InputDecoration(labelText: "Type other observations"),
              ),
              const SizedBox(height: 10),

              // Upload or Capture Photo section
              const Text(
                "Upload Photos (Max 5)",
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

              // Display thumbnails of uploaded photos
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _photoPaths.map((path) {
                  int index = _photoPaths.indexOf(path);
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(File(path), width: 70, height: 70, fit: BoxFit.cover),
                      GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Save button
              Center(
                child: ElevatedButton(
                  onPressed: _saveForm,
                  child: const Text("update"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
