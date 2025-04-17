import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/misdelivery.dart';
import '../../services/update_transaction.dart';

class MisdeliveryPage extends StatefulWidget {
  final MisdeliveryTransaction transaction;
  final Function(bool) onSave;

  const MisdeliveryPage({
    Key? key,
    required this.transaction,
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
    print('MisdeliveryPage - Transaction Details:');
    print('  MainDraftId: ${widget.transaction.mainDraftId}');
    print('  BlockNumber: ${widget.transaction.blockNumber}');
    print('  PostalCode: ${widget.transaction.postalCode}');
    print('  Date: ${widget.transaction.date}');
    print('  Misdeliveries: ${widget.transaction.misdeliveries.length}');
    
    // Debug log each misdelivery
    for (var m in widget.transaction.misdeliveries) {
      print('  Misdelivery:');
      print('    ID: ${m.id}');
      print('    IsPostalCode: ${m.isPostalCode}');
      print('    FoundAt: ${m.foundAt}');
      print('    MeantFor: ${m.meantFor}');
    }
    
    // Initialize inputs from transaction's misdeliveries
    _inputs = widget.transaction.misdeliveries.map((m) {
      print('Creating input for misdelivery ID: ${m.id}'); // Debug log
      return {
        'id': m.id, // Include the misdelivery ID
        'isPostalCode': m.isPostalCode,
        'foundAt': Map<String, dynamic>.from(m.foundAt),
        'meantFor': Map<String, dynamic>.from(m.meantFor),
      };
    }).toList();
    
    // Debug log the inputs
    print('Initialized inputs:');
    for (var input in _inputs) {
      print('  Input:');
      print('    ID: ${input['id']}');
      print('    IsPostalCode: ${input['isPostalCode']}');
      print('    FoundAt: ${input['foundAt']}');
      print('    MeantFor: ${input['meantFor']}');
    }
    
    // Initialize controllers for each row
    for (var row in _inputs) {
      _initializeRowControllers(row);
    }
    
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
      final id = row['id']; // Preserve the ID
      final isPostalCode = row['isPostalCode']; // Preserve the mode
      
      if (isPostalCode) {
        row['foundAt'] = Map<String, dynamic>.from({
          'postalCode': row['foundAtControllers']['postalCode'].text
        });
        row['meantFor'] = Map<String, dynamic>.from({
          'postalCode': row['meantForControllers']['postalCode'].text
        });
      } else {
        row['foundAt'] = Map<String, dynamic>.from({
          'floor': row['foundAtControllers']['floor'].text,
          'unit': row['foundAtControllers']['unit'].text
        });
        row['meantFor'] = Map<String, dynamic>.from({
          'floor': row['meantForControllers']['floor'].text,
          'unit': row['meantForControllers']['unit'].text
        });
      }
      
      // Restore preserved values
      row['id'] = id;
      row['isPostalCode'] = isPostalCode;
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
      
      // Create a map of existing IDs from the transaction
      Map<int, Map<String, dynamic>> existingData = {};
      for (var m in widget.transaction.misdeliveries) {
        existingData[m.id] = {
          'id': m.id,
          'isPostalCode': m.isPostalCode,
          'foundAt': m.foundAt,
          'meantFor': m.meantFor,
        };
      }
      
      // Merge loaded data with existing IDs
      _inputs = loaded.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> loadedData = entry.value as Map<String, dynamic>;
        
        // Get the corresponding misdelivery from the transaction
        if (index < widget.transaction.misdeliveries.length) {
          var misdelivery = widget.transaction.misdeliveries[index];
          loadedData['id'] = misdelivery.id; // Preserve the original ID
        }
        
        return loadedData;
      }).toList();

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
    // Check if there are rows or if "No Misdelivery Found" is checked
    if ((_inputs.isEmpty && !_noMisdeliveryFound) || (_inputs.isNotEmpty && !_areAllRowsFilled())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Please fill in all fields in each row or remove empty rows before submitting"),
        ),
      );
      return;
    }

    _updateRowDataFromControllers();
    
    // Debug log before preparing data for update
    print('DEBUG: Preparing data for update:');
    for (var input in _inputs) {
      print('DEBUG: Input before cleanup:');
      print('DEBUG:   ID: ${input['id']} (${input['id']?.runtimeType})');
      print('DEBUG:   IsPostalCode: ${input['isPostalCode']}');
      print('DEBUG:   FoundAt: ${input['foundAt']}');
      print('DEBUG:   MeantFor: ${input['meantFor']}');
    }
    
    // Remove controllers before saving because they cannot be sent to API
    List<Map<String, dynamic>> dataToUpdate = _inputs.map((row) {
      Map<String, dynamic> copy = Map<String, dynamic>.from(row);
      copy.remove('foundAtControllers');
      copy.remove('meantForControllers');
      return copy;
    }).toList();

    // Debug log after preparing data
    print('DEBUG: Data prepared for update:');
    for (var data in dataToUpdate) {
      print('DEBUG: Data after cleanup:');
      print('DEBUG:   ID: ${data['id']} (${data['id']?.runtimeType})');
      print('DEBUG:   IsPostalCode: ${data['isPostalCode']}');
      print('DEBUG:   FoundAt: ${data['foundAt']}');
      print('DEBUG:   MeantFor: ${data['meantFor']}');
    }

    try {
      print('DEBUG: Sending data to UpdateTransactionService:');
      for (var data in dataToUpdate) {
        print('DEBUG:   Sending ID: ${data['id']} (${data['id']?.runtimeType})');
      }
      
      final success = await UpdateTransactionService.updateMisdelivery(
        context,
        widget.transaction,
        dataToUpdate,
      );

      if (success) {
        await _saveDraft(); // Still save to local storage
        setState(() => _formCompleted = true);
        widget.onSave(true);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update misdelivery. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating misdelivery: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            Text('Postal Code: ${widget.transaction.postalCode}'),
            Text('Block Number: ${widget.transaction.blockNumber}'),
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
                                      final id = row['id']; // Preserve the ID
                                      row['isPostalCode'] = value;
                                      if (value) {
                                        row['foundAt'] = {'postalCode': ''};
                                        row['meantFor'] = {'postalCode': ''};
                                      } else {
                                        row['foundAt'] = {'floor': '', 'unit': ''};
                                        row['meantFor'] = {'floor': '', 'unit': ''};
                                      }
                                      row['id'] = id; // Restore the ID
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
            const SizedBox(height: 10),
            // Single row for buttons.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveForm,
                  child: const Text('update'),
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
