import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription.dart';

class Company {
  final String id;
  final String name;
  final String? address;
  final String? taxNumber;
  final String? registrationNumber;
  final String? vatNumber;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final CompanySettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Subscription? subscription;
  final bool isAdmin;

  Company({
    required this.id,
    required this.name,
    this.address,
    this.taxNumber,
    this.registrationNumber,
    this.vatNumber,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.subscription,
    this.isAdmin = false,
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'],
      taxNumber: data['taxNumber'],
      registrationNumber: data['registrationNumber'],
      vatNumber: data['vatNumber'],
      phone: data['phone'],
      email: data['email'],
      website: data['website'],
      logoUrl: data['logoUrl'],
      settings: CompanySettings.fromMap(data['settings'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      subscription: null, // Will be loaded separately
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  static Future<Company> fromFirestoreWithSubscription(
      DocumentSnapshot doc) async {
    final company = Company.fromFirestore(doc);
    final subscriptionDoc =
        await doc.reference.collection('subscription').doc('current').get();
    if (subscriptionDoc.exists) {
      return company.copyWith(
        subscription: Subscription.fromFirestore(subscriptionDoc),
      );
    }
    return company;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'taxNumber': taxNumber,
      'registrationNumber': registrationNumber,
      'vatNumber': vatNumber,
      'phone': phone,
      'email': email,
      'website': website,
      'logoUrl': logoUrl,
      'settings': settings.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'subscription': subscription?.toMap(),
      'isAdmin': isAdmin,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? address,
    String? taxNumber,
    String? registrationNumber,
    String? vatNumber,
    String? phone,
    String? email,
    String? website,
    String? logoUrl,
    CompanySettings? settings,
    Subscription? subscription,
    bool? isAdmin,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vatNumber: vatNumber ?? this.vatNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
      subscription: subscription ?? this.subscription,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class CompanySettings {
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankRoutingNumber;
  final String? bankSwiftCode;
  final String? bankIban;
  final String currency;
  final double defaultTaxRate;
  final String invoicePrefix;
  final int paymentTerms;
  final int nextInvoiceNumber;

  const CompanySettings({
    this.bankName,
    this.bankAccountNumber,
    this.bankRoutingNumber,
    this.bankSwiftCode,
    this.bankIban,
    this.currency = 'USD',
    this.defaultTaxRate = 0.0,
    this.invoicePrefix = 'INV',
    this.paymentTerms = 30,
    this.nextInvoiceNumber = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankRoutingNumber': bankRoutingNumber,
      'bankSwiftCode': bankSwiftCode,
      'bankIban': bankIban,
      'currency': currency,
      'defaultTaxRate': defaultTaxRate,
      'invoicePrefix': invoicePrefix,
      'paymentTerms': paymentTerms,
      'nextInvoiceNumber': nextInvoiceNumber,
    };
  }

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      bankName: map['bankName'] as String?,
      bankAccountNumber: map['bankAccountNumber'] as String?,
      bankRoutingNumber: map['bankRoutingNumber'] as String?,
      bankSwiftCode: map['bankSwiftCode'] as String?,
      bankIban: map['bankIban'] as String?,
      currency: map['currency'] as String? ?? 'USD',
      defaultTaxRate: (map['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV',
      paymentTerms: map['paymentTerms'] as int? ?? 30,
      nextInvoiceNumber: map['nextInvoiceNumber'] as int? ?? 1,
    );
  }

  CompanySettings copyWith({
    String? bankName,
    String? bankAccountNumber,
    String? bankRoutingNumber,
    String? bankSwiftCode,
    String? bankIban,
    String? currency,
    double? defaultTaxRate,
    String? invoicePrefix,
    int? paymentTerms,
    int? nextInvoiceNumber,
  }) {
    return CompanySettings(
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankRoutingNumber: bankRoutingNumber ?? this.bankRoutingNumber,
      bankSwiftCode: bankSwiftCode ?? this.bankSwiftCode,
      bankIban: bankIban ?? this.bankIban,
      currency: currency ?? this.currency,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
    );
  }
}
