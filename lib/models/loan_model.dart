class Loan {
  final int id;
  final int materialId;
  final String materialName;
  final String? materialImageUrl;
  final int quantity;
  final String status; // active, returned, overdue, lost
  final DateTime issuedAt;
  final DateTime expectedReturnDate;
  final DateTime? actualReturnDate;
  final String? condition;
  final String? qrToken;
  final int? loanRequestId;
  final String? damageNotes;
  final int? borrowerId;
  final String? borrowerName;
  final bool isConsumable;

  Loan({
    required this.id,
    required this.materialId,
    required this.materialName,
    this.materialImageUrl,
    required this.quantity,
    required this.status,
    required this.issuedAt,
    required this.expectedReturnDate,
    this.actualReturnDate,
    this.condition,
    this.qrToken,
    this.loanRequestId,
    this.damageNotes,
    this.borrowerId,
    this.borrowerName,
    this.isConsumable = false,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    final materialDetail = json['material_detail'];
    final int matId = materialDetail is Map
        ? (materialDetail['id'] as int? ?? 0)
        : (json['material'] as int? ?? 0);
    final String matName = materialDetail is Map
        ? (materialDetail['name'] as String? ?? 'Material desconocido')
        : 'Material desconocido';
    final String? matImage = materialDetail is Map
        ? materialDetail['image'] as String?
        : null;
    final bool matIsConsumable = materialDetail is Map
        ? (materialDetail['is_consumable'] as bool? ?? false)
        : false;

    final borrowerDetail = json['borrower_detail'];
    final int? borrowerId = borrowerDetail is Map
        ? (borrowerDetail['id'] as int?)
        : (json['borrower'] as int?);
    final String? borrowerName = borrowerDetail is Map
        ? (borrowerDetail['full_name'] as String? ?? borrowerDetail['email'] as String?)
        : null;

    return Loan(
      id: json['id'] as int? ?? 0,
      materialId: matId,
      materialName: matName,
      materialImageUrl: matImage,
      quantity: json['quantity_loaned'] as int? ?? json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'unknown',
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'] as String)
          : DateTime.now(),
      expectedReturnDate: json['expected_return_date'] != null
          ? DateTime.parse(json['expected_return_date'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      actualReturnDate: json['actual_return_date'] != null
          ? DateTime.tryParse(json['actual_return_date'] as String)
          : null,
      condition: json['condition'] as String?,
      qrToken: json['qr_token'] as String?,
      loanRequestId: json['loan_request'] as int?,
      damageNotes: json['damage_notes'] as String?,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      isConsumable: matIsConsumable,
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    return expectedReturnDate.difference(now).inDays;
  }

  bool get isOverdue => status == 'overdue' || daysRemaining < 0;

  String get statusLabel {
    if (isConsumable && status == 'returned') return 'Recibido';
    const labels = {
      'active': 'Activo',
      'returned': 'Devuelto',
      'overdue': 'Vencido',
      'lost': 'Perdido',
    };
    return labels[status] ?? status;
  }
}

class LoanExtension {
  final int id;
  final int loanId;
  final DateTime newReturnDate;
  final String? reason;
  final String status; // pending, approved, rejected

  LoanExtension({
    required this.id,
    required this.loanId,
    required this.newReturnDate,
    this.reason,
    required this.status,
  });

  factory LoanExtension.fromJson(Map<String, dynamic> json) {
    return LoanExtension(
      id: json['id'] as int? ?? 0,
      loanId: json['loan'] as int? ?? 0,
      newReturnDate: json['new_return_date'] != null
          ? DateTime.parse(json['new_return_date'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
