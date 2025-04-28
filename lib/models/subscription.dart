import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, basic, professional, enterprise }

class Subscription {
  final String id;
  final String companyId;
  final String plan;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.companyId,
    required this.plan,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'plan': plan,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      companyId: data['companyId'],
      plan: data['plan'],
      status: data['status'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  static List<String> getFeaturesForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return [
          'basic_invoicing',
          'up_to_5_clients',
          'basic_reports',
        ];
      case SubscriptionTier.basic:
        return [
          'basic_invoicing',
          'unlimited_clients',
          'basic_reports',
          'invoice_templates',
          'email_notifications',
        ];
      case SubscriptionTier.professional:
        return [
          'basic_invoicing',
          'unlimited_clients',
          'advanced_reports',
          'invoice_templates',
          'email_notifications',
          'recurring_invoices',
          'client_portal',
          'payment_integrations',
        ];
      case SubscriptionTier.enterprise:
        return [
          'basic_invoicing',
          'unlimited_clients',
          'advanced_reports',
          'invoice_templates',
          'email_notifications',
          'recurring_invoices',
          'client_portal',
          'payment_integrations',
          'api_access',
          'custom_branding',
          'priority_support',
        ];
    }
  }
}
