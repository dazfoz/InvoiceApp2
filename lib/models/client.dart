import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String companyId;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.companyId,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.taxNumber,
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      companyId: doc.reference.parent.parent!.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      address: data['address'],
      taxNumber: data['taxNumber'],
      additionalInfo: data['additionalInfo'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'taxNumber': taxNumber,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Client copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? taxNumber,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Client(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
