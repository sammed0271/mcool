class PartUsage {
  final int? id;
  final int invoiceId;
  final int? repairId;
  final int partId;
  final int quantityUsed;
  final DateTime usedAt;
  final String? technicianNotes;

  const PartUsage({this.id, required this.invoiceId, this.repairId, required this.partId, required this.quantityUsed, required this.usedAt, this.technicianNotes});

  factory PartUsage.fromMap(Map<String, dynamic> map) => PartUsage(
        id: (map['id'] as num?)?.toInt(),
        invoiceId: (map['invoice_id'] as num).toInt(),
        repairId: (map['repair_id'] as num?)?.toInt(),
        partId: (map['part_id'] as num).toInt(),
        quantityUsed: (map['quantity_used'] as num).toInt(),
        usedAt: DateTime.parse(map['used_at'] as String),
        technicianNotes: map['technician_notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'repair_id': repairId,
        'part_id': partId,
        'quantity_used': quantityUsed,
        'used_at': usedAt.toIso8601String(),
        'technician_notes': technicianNotes,
      };
}
