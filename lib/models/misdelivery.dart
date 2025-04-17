import 'dart:convert';

class MisdeliveryTransaction {
  final int id;
  final int mainDraftId;
  final String blockNumber;
  final String postalCode;
  final String date;
  final List<Misdelivery> misdeliveries;
  final MainDraft? mainDraft;

  MisdeliveryTransaction({
    required this.id,
    required this.mainDraftId,
    required this.blockNumber,
    required this.postalCode,
    required this.date,
    required this.misdeliveries,
    this.mainDraft,
  });

  factory MisdeliveryTransaction.fromJson(int key, Map<String, dynamic> json) {
    return MisdeliveryTransaction(
      id: key,
      mainDraftId: json['mainDraft']?['id'] ?? 0,
      blockNumber: json['mainDraft']?['block_number'] ?? '',
      postalCode: json['mainDraft']?['postal_code']?.toString() ?? '',
      date: json['mainDraft']?['createdAt'] ?? '',
      misdeliveries: (json['misdeliveries'] as List<dynamic>? ?? [])
          .map((item) => Misdelivery.fromJson(item))
          .toList(),
      mainDraft: json['mainDraft'] != null 
          ? MainDraft.fromJson(json['mainDraft']) 
          : null,
    );
  }

  String get displayTitle {
    return '$blockNumber - $postalCode';
  }
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
    Map<String, dynamic> parseJsonString(String? jsonStr) {
      if (jsonStr == null) return {};
      try {
        return jsonDecode(jsonStr);
      } catch (e) {
        print('Error parsing JSON string: $e');
        return {};
      }
    }

    return Misdelivery(
      id: json['id'] ?? 0,
      foundAt: parseJsonString(json['foundAt']),
      meantFor: parseJsonString(json['meantFor']),
      mainDraftId: json['main_draft_id'] ?? 0,
      isPostalCode: json['isPostalCode'] ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class MainDraft {
  final int id;
  final int userId;
  final int postalCode;
  final String blockNumber;
  final int nest;
  final String createdAt;
  final String updatedAt;

  MainDraft({
    required this.id,
    required this.userId,
    required this.postalCode,
    required this.blockNumber,
    required this.nest,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MainDraft.fromJson(Map<String, dynamic> json) {
    return MainDraft(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      postalCode: json['postal_code'] ?? 0,
      blockNumber: json['block_number'] ?? '',
      nest: json['nest'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
