import 'dart:convert';

class MisdeliveryTransaction {
  final int mainDraftId;
  final String blockNumber;
  final String postalCode;
  final String date;
  final List<Misdelivery> misdeliveries;

  MisdeliveryTransaction({
    required this.mainDraftId,
    required this.blockNumber,
    required this.postalCode,
    required this.date,
    List<Misdelivery>? misdeliveries,
  }) : this.misdeliveries = misdeliveries ?? [];

  factory MisdeliveryTransaction.fromJson(int key, Map<String, dynamic> value) {
    print('Parsing MisdeliveryTransaction JSON:');
    print('  Key: $key');
    print('  Value: $value');
    
    final mainDraft = value['mainDraft'] ?? {};
    List<Misdelivery> misdeliveriesList = [];
    
    if (value['misdeliveries'] != null) {
      try {
        print('  Misdeliveries array: ${value['misdeliveries']}');
        misdeliveriesList = (value['misdeliveries'] as List)
            .map((m) {
              print('  Processing misdelivery: $m');
              return Misdelivery.fromJson(m);
            })
            .toList();
      } catch (e) {
        print('Error parsing misdeliveries: $e');
      }
    }
    
    return MisdeliveryTransaction(
      mainDraftId: key,
      blockNumber: mainDraft['block_number']?.toString() ?? '',
      postalCode: (mainDraft['postal_code'] ?? '').toString(),
      date: mainDraft['createdAt']?.toString() ?? '',
      misdeliveries: misdeliveriesList,
    );
  }

  // 👇 This is the getter you're missing
  String get displayTitle => 'Misdelivery #$mainDraftId';
}

class Misdelivery {
  final int id;
  final Map<String, dynamic> foundAt;
  final Map<String, dynamic> meantFor;
  final int mainDraftId;
  final bool isPostalCode;
  final String createdAt;

  Misdelivery({
    required this.id,
    required this.foundAt,
    required this.meantFor,
    required this.mainDraftId,
    required this.isPostalCode,
    required this.createdAt,
  });

  factory Misdelivery.fromJson(Map<String, dynamic> json) {
    print('Parsing Misdelivery JSON: $json'); // Debug log
    Map<String, dynamic> parseJsonString(String? jsonStr) {
      if (jsonStr == null) return {};
      try {
        return jsonDecode(jsonStr);
      } catch (e) {
        print('Error parsing JSON string: $e');
        return {};
      }
    }

    final id = json['id'];
    print('Misdelivery ID from JSON: $id'); // Debug log

    return Misdelivery(
      id: id ?? 0,
      foundAt: parseJsonString(json['foundAt']),
      meantFor: parseJsonString(json['meantFor']),
      mainDraftId: json['main_draft_id'] ?? 0,
      isPostalCode: json['isPostalCode'] ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
