import 'package:intl/intl.dart';

enum CreditStatus { active, overdue, paid }

class CreditModel {
  final String id;
  final String creditorId;
  final String debtorName;
  final String debtorPhone;
  final double amount;
  final double amountPaid;
  final DateTime dueDate;
  final CreditStatus status;
  final String notes;
  final DateTime createdAt;

  const CreditModel({
    required this.id,
    required this.creditorId,
    required this.debtorName,
    this.debtorPhone = '',
    required this.amount,
    this.amountPaid = 0,
    required this.dueDate,
    required this.status,
    this.notes = '',
    required this.createdAt,
  });

  double get remaining => amount - amountPaid;
  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != CreditStatus.paid;
  String get formattedDue => DateFormat('d MMM yyyy').format(dueDate);

  factory CreditModel.fromMap(Map<String, dynamic> m, String id) => CreditModel(
        id: id,
        creditorId: m['creditorId'] as String? ?? '',
        debtorName: m['debtorName'] as String? ?? '',
        debtorPhone: m['debtorPhone'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        amountPaid: (m['amountPaid'] as num?)?.toDouble() ?? 0,
        dueDate:
            DateTime.tryParse(m['dueDate'] as String? ?? '') ?? DateTime.now(),
        status: CreditStatus.values.firstWhere(
          (e) => e.name == (m['status'] as String? ?? 'active'),
          orElse: () => CreditStatus.active,
        ),
        notes: m['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'creditorId': creditorId,
        'debtorName': debtorName,
        'debtorPhone': debtorPhone,
        'amount': amount,
        'amountPaid': amountPaid,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}
