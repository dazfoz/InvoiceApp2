import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled,
}

class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
    );
  }
}

class Invoice {
  final String id;
  final String companyId;
  final String clientId;
  final String number;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final String notes;
  final InvoiceStatus status;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.companyId,
    required this.clientId,
    required this.number,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.notes,
    required this.status,
    this.paymentMethod,
    this.paidAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxAmount => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => items.fold(0, (sum, item) => sum + item.total);

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      companyId: doc.reference.parent.parent!.id,
      clientId: data['clientId'] ?? '',
      number: data['number'] ?? '',
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      items: (data['items'] as List?)
              ?.map((item) => InvoiceItem.fromMap(item))
              .toList() ??
          [],
      notes: data['notes'] ?? '',
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString() == 'InvoiceStatus.${data['status']}',
        orElse: () => InvoiceStatus.draft,
      ),
      paymentMethod: data['paymentMethod'],
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'number': number,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'items': items.map((item) => item.toMap()).toList(),
      'notes': notes,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Invoice copyWith({
    String? clientId,
    String? number,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    String? notes,
    InvoiceStatus? status,
    String? paymentMethod,
    DateTime? paidAt,
  }) {
    return Invoice(
      id: id,
      companyId: companyId,
      clientId: clientId ?? this.clientId,
      number: number ?? this.number,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
