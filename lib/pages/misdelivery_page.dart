import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MisdeliveryPage extends StatefulWidget {
  final String postalCode;
  final String buildingNumber;
  final Function(bool) onSave;

  const MisdeliveryPage({
    Key? key,
    required this.postalCode,
    required this.buildingNumber,
    required this.onSave,
  }) : super(key: key);

  @override
  _MisdeliveryPageState createState() => _MisdeliveryPageState();
}

class _MisdeliveryPageState extends State<MisdeliveryPage> {
  bool _formCompleted = false;
  bool _noMisdeliveryFound = false; // Checkbox state
  List<Map<String, dynamic>> _inputs = []; // Holds the dynamic row data

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  /// Create text controllers for each row based on the mode.
  void _initializeRowControllers(Map<String, dynamic> row) {
    if (row['isPostalCode'] == true) {
      row['foundAtControllers'] = {
        'postalCode': TextEditingController(
          text: row['foundAt']?['postalCode']?.toString() ?? '',
        ),
      };
      row['meantForControllers'] = {
        'postalCode': TextEditingController(
          text: row['meantFor']?['postalCode']?.toString() ?? '',
        ),
      };
    } else {
      row['foundAtControllers'] = {
        'floor': TextEditingController(
          text: row['foundAt']?['floor']?.toString() ?? '',
        ),
        'unit': TextEditingController(
          text: row['foundAt']?['unit']?.toString() ?? '',
        ),
      };
      row['meantForControllers'] = {
        'floor': TextEditingController(
          text: row['meantFor']?['floor']?.toString() ?? '',
        ),
        'unit': TextEditingController(
          text: row['meantFor']?['unit']?.toString() ?? '',
        ),
      };
    }
  }

  /// Update each row's data from its text controllers.
  void _updateRowDataFromControllers() {
    for (var row in _inputs) {
      if (row['isPostalCode'] == true) {
        row['foundAt']['postalCode'] =
            row['foundAtControllers']['postalCode'].text;
        row['meantFor']['postalCode'] =
            row['meantForControllers']['postalCode'].text;
      } else {
        row['foundAt']['floor'] = row['foundAtControllers']['floor'].text;
        row['foundAt']['unit'] = row['foundAtControllers']['unit'].text;
        row['meantFor']['floor'] = row['meantForControllers']['floor'].text;
        row['meantFor']['unit'] = row['meantForControllers']['unit'].text;
      }
    }
  }

Future<void> _saveDraft() async {
  _updateRowDataFromControllers();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Remove controllers before saving because they cannot be encoded.
  List<Map<String, dynamic>> dataToSave = _inputs.map((row) {
    Map<String, dynamic> copy = Map<String, dynamic>.from(row);
    copy.remove('foundAtControllers');
    copy.remove('meantForControllers');
    return copy;
  }).toList();

  // Create a Map to store both the draft and checkbox state
  Map<String, dynamic> data = {
    'draft': dataToSave,
    'noMisdeliveryFound': _noMisdeliveryFound,
  };

  // Convert the Map to a JSON string
  String jsonData = jsonEncode(data);

  // Save the JSON string in SharedPreferences
  await prefs.setString('misDeliveryDraft', jsonData);
}

/// Load the saved draft and initialize controllers and checkbox state.
Future<void> _loadDraft() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Get the stored JSON string
  String? jsonData = prefs.getString('misDeliveryDraft');

  if (jsonData != null) {
    // Decode the JSON string to a Map
    Map<String, dynamic> data = jsonDecode(jsonData);

    // Load the checkbox state
    bool savedCheckbox = data['noMisdeliveryFound'] ?? false;
    _noMisdeliveryFound = savedCheckbox;

    // Load the draft data
    List<dynamic> loaded = data['draft'];
    _inputs = loaded.map((e) => e as Map<String, dynamic>).toList();

    // Initialize controllers for the loaded rows
    for (var row in _inputs) {
      _initializeRowControllers(row);
    }

    setState(() {});
  } else {
    // Handle case where no data is found
    print('No saved data found');
  }
}

  /// Check whether all rows are fully filled.
  bool _areAllRowsFilled() {
    for (var row in _inputs) {
      if (row['isPostalCode'] == true) {
        String foundPostal =
            row['foundAtControllers']['postalCode'].text.trim();
        String meantPostal =
            row['meantForControllers']['postalCode'].text.trim();
        if (foundPostal.isEmpty || meantPostal.isEmpty) return false;
      } else {
        String foundFloor = row['foundAtControllers']['floor'].text.trim();
        String foundUnit = row['foundAtControllers']['unit'].text.trim();
        String meantFloor = row['meantForControllers']['floor'].text.trim();
        String meantUnit = row['meantForControllers']['unit'].text.trim();
        if (foundFloor.isEmpty ||
            foundUnit.isEmpty ||
            meantFloor.isEmpty ||
            meantUnit.isEmpty) return false;
      }
    }
    return true;
  }

  void _saveForm() async {
    // Validate that each row is filled if misdelivery details are expected.
  if (!_noMisdeliveryFound && _inputs.isNotEmpty && !_areAllRowsFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Please fill in all fields in each row or remove empty rows before saving."),
        ),
      );
      return;
    }

    await _saveDraft();
    setState(() => _formCompleted = true);
    widget.onSave(true);
    Navigator.pop(context);
  }

  /// Add a new row with empty fields.
  void _addRow() {
    Map<String, dynamic> newRow = {
      'isPostalCode': false, // Default mode: Floor/Unit
      'foundAt': {'floor': '', 'unit': ''},
      'meantFor': {'floor': '', 'unit': ''},
    };
    _initializeRowControllers(newRow);
    setState(() {
      _inputs.add(newRow);
    });
  }

  void _removeRow(int index) {
    var row = _inputs[index];
    if (row['foundAtControllers'] != null) {
      (row['foundAtControllers'] as Map<String, TextEditingController>)
          .values
          .forEach((c) => c.dispose());
    }
    if (row['meantForControllers'] != null) {
      (row['meantForControllers'] as Map<String, TextEditingController>)
          .values
          .forEach((c) => c.dispose());
    }
    setState(() {
      _inputs.removeAt(index);
    });
  }

  void _clearDraft() {
    for (var row in _inputs) {
      if (row['foundAtControllers'] != null) {
        (row['foundAtControllers'] as Map<String, TextEditingController>)
            .values
            .forEach((c) => c.dispose());
      }
      if (row['meantForControllers'] != null) {
        (row['meantForControllers'] as Map<String, TextEditingController>)
            .values
            .forEach((c) => c.dispose());
      }
    }
    setState(() {
      _inputs.clear();
    });
  }

  @override
  void dispose() {
    for (var row in _inputs) {
      if (row['foundAtControllers'] != null) {
        (row['foundAtControllers'] as Map<String, TextEditingController>)
            .values
            .forEach((c) => c.dispose());
      }
      if (row['meantForControllers'] != null) {
        (row['meantForControllers'] as Map<String, TextEditingController>)
            .values
            .forEach((c) => c.dispose());
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Misdelivery Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Postal Code: ${widget.postalCode}'),
            Text('Building Number: ${widget.buildingNumber}'),
            const SizedBox(height: 20),
            // Display dynamic rows or a message if no misdelivery is found.
            Expanded(
              child: !_noMisdeliveryFound
                  ? ListView.builder(
                      itemCount: _inputs.length,
                      itemBuilder: (context, index) {
                        var row = _inputs[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toggle switch row.
                            Row(
                              children: [
                                const Text("Mode: "),
                                Switch(
                                  value: row['isPostalCode'],
                                  onChanged: (bool value) {
                                    setState(() {
                                      row['isPostalCode'] = value;
                                      if (value) {
                                        row['foundAt'] = {'postalCode': ''};
                                        row['meantFor'] = {'postalCode': ''};
                                      } else {
                                        row['foundAt'] = {'floor': '', 'unit': ''};
                                        row['meantFor'] = {'floor': '', 'unit': ''};
                                      }
                                      if (row['foundAtControllers'] != null) {
                                        (row['foundAtControllers']
                                                as Map<String, TextEditingController>)
                                            .values
                                            .forEach((c) => c.dispose());
                                      }
                                      if (row['meantForControllers'] != null) {
                                        (row['meantForControllers']
                                                as Map<String, TextEditingController>)
                                            .values
                                            .forEach((c) => c.dispose());
                                      }
                                      _initializeRowControllers(row);
                                    });
                                  },
                                ),
                                Text(row['isPostalCode']
                                    ? "Postal Code"
                                    : "Floor/Unit"),
                              ],
                            ),
                            // Row with Found At, Meant For, and delete button.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Found At Section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Found At",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      row['isPostalCode']
                                          ? TextField(
                                              controller: row[
                                                  'foundAtControllers']
                                                  ['postalCode'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Postal Code',
                                                hintText: 'Postal Code',
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                Flexible(
                                                  child: TextField(
                                                    controller: row[
                                                            'foundAtControllers']
                                                        ['floor'],
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Floor',
                                                      hintText: 'Floor',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: TextField(
                                                    controller: row[
                                                            'foundAtControllers']
                                                        ['unit'],
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Unit',
                                                      hintText: 'Unit',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Meant For Section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Meant For",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      row['isPostalCode']
                                          ? TextField(
                                              controller: row[
                                                  'meantForControllers']
                                                  ['postalCode'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Postal Code',
                                                hintText: 'Postal Code',
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                Flexible(
                                                  child: TextField(
                                                    controller: row[
                                                            'meantForControllers']
                                                        ['floor'],
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Floor',
                                                      hintText: 'Floor',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: TextField(
                                                    controller: row[
                                                            'meantForControllers']
                                                        ['unit'],
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Unit',
                                                      hintText: 'Unit',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                                // Delete Button
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeRow(index),
                                ),
                              ],
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        "No misdelivery details required.",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
            ),
            // Checkbox placed directly above the button row.
            CheckboxListTile(
              title: const Text("No misdelivery found"),
              value: _noMisdeliveryFound,
              onChanged: (bool? value) {
                setState(() {
                  _noMisdeliveryFound = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 10),
            // Single row for buttons.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_noMisdeliveryFound) ...[
                  ElevatedButton(
                    onPressed: _addRow,
                    child: const Text('Add Row'),
                  ),
                  ElevatedButton(
                    onPressed: _clearDraft,
                    child: const Text('Clear Draft'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
                ElevatedButton(
                  onPressed: _saveForm,
                  child: const Text('Save as Draft'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
