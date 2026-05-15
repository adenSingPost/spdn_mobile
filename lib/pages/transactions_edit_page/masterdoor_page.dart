import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/masterdoor.dart';
import '../../services/update_transaction.dart';
import '../../utils/transaction_image.dart';

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
  final TextEditingController _observationsController = TextEditingController();
  /// From server — for review only (URLs).
  List<String> _existingImageUrls = [];
  /// New local files to upload on update.
  final List<String> _newPhotoPaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _masterDoorStatus = widget.transaction.checklistOption;
    _observationsController.text = widget.transaction.observation ?? '';
    _existingImageUrls = widget.transaction.imageList
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map(resolveTransactionImageUrl)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (_masterDoorStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a Masterdoor status before saving."),
        ),
      );
      return;
    }

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

    if (confirmed != true) {
      return;
    }

    try {
      final success = await UpdateTransactionService.updateMasterdoor(
        context,
        widget.transaction,
        _masterDoorStatus!,
        _observationsController.text,
        _newPhotoPaths,
      );

      if (success) {
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

  Future<void> _pickPhoto(ImageSource source) async {
    if (_newPhotoPaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can upload a maximum of 5 photos.")),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      final persisted = await persistQcDraftPhoto(photo);
      setState(() {
        _newPhotoPaths.add(persisted);
      });
    }
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotoPaths.removeAt(index);
    });
  }

  void _onRadioChanged(int? value) {
    setState(() {
      _masterDoorStatus = value;
    });
  }

  Widget _networkThumb(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 70,
          height: 70,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
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
              Text(
                "Postal Code: ${widget.transaction.postalCode}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Building Number: ${widget.transaction.buildingNumber}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              const Text(
                "Masterdoor Checklist",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

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

              TextField(
                controller: _observationsController,
                decoration: const InputDecoration(labelText: "Type other observations"),
              ),
              const SizedBox(height: 10),

              if (_existingImageUrls.isNotEmpty) ...[
                const Text(
                  "Saved photos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _existingImageUrls
                      .map((url) => _networkThumb(url))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                "Add photos (Max 5)",
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

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _newPhotoPaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final path = entry.value;
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(File(path), width: 70, height: 70, fit: BoxFit.cover),
                      GestureDetector(
                        onTap: () => _removeNewPhoto(index),
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
