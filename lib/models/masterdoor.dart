class MasterdoorTransaction {
  final int id;
  final int checklistOption;
  final String? observation;
  final List<String> imageList;
  final String mainDraftId;
  final String createdAt;
  final String updatedAt;
  final MainDraft mainDraft;

  MasterdoorTransaction({
    required this.id,
    required this.checklistOption,
    this.observation,
    required this.imageList,
    required this.mainDraftId,
    required this.createdAt,
    required this.updatedAt,
    required this.mainDraft,
  });

  String get displayTitle => '${mainDraft.blockNumber} - ${mainDraft.postalCode}';

  factory MasterdoorTransaction.fromJson(Map<String, dynamic> json) {
    List<String> imageList = _parseImageListField(json['imageList']);

    return MasterdoorTransaction(
      id: json['id'],
      checklistOption: json['checklist_option'],
      observation: json['observation'],
      imageList: imageList,
      mainDraftId: json['main_draft_id'].toString(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      mainDraft: MainDraft.fromJson(json['MainDraft']),
    );
  }

  String get postalCode => mainDraft.postalCode.toString();
  String get buildingNumber => mainDraft.blockNumber;
  String get date => createdAt;

  static List<String> _parseImageListField(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return [];
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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
      id: json['id'],
      userId: json['user_id'],
      postalCode: json['postal_code'],
      blockNumber: json['block_number'],
      nest: json['nest'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
} 