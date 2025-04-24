class ReturnMailboxTransaction {
  final int id;
  final int checklistOption;
  final String observation;
  final List<String> imageList;
  final int mainDraftId;
  final String createdAt;
  final String updatedAt;
  final MainDraft? mainDraft;

  ReturnMailboxTransaction({
    required this.id,
    required this.checklistOption,
    required this.observation,
    required this.imageList,
    required this.mainDraftId,
    required this.createdAt,
    required this.updatedAt,
    this.mainDraft,
  });

  factory ReturnMailboxTransaction.fromJson(Map<String, dynamic> json) {

    return ReturnMailboxTransaction(
      id: json['id'] ?? 0,
      checklistOption: json['checklist'] ?? 0,
      observation: json['observation'] ?? '',
      imageList: json['imageList'] != null && json['imageList'].toString().isNotEmpty
          ? json['imageList'].toString().split(',')
          : [],
      mainDraftId: json['main_draft_id'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      mainDraft: json['MainDraft'] != null 
          ? MainDraft.fromJson(json['MainDraft']) 
          : null,
    );
  }

  String getDisplayTitle() {
    if (mainDraft != null) {
      return '${mainDraft!.blockNumber} - ${mainDraft!.postalCode}';
    }
    return 'Return Mailbox #$id';
  }

  String get postalCode => mainDraft?.postalCode.toString() ?? '';
  String get buildingNumber => mainDraft?.blockNumber ?? '';
  String get date => createdAt;
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