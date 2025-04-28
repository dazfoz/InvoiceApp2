import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/company.dart';
import '../models/subscription.dart';
import '../models/company_user.dart';

class TestUsers {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createTestUsers() async {
    print('Starting test user creation process...');

    try {
      // Create Free user
      print('Creating Free user...');
      final freeUser = await _auth.createUserWithEmailAndPassword(
        email: 'free@test.com',
        password: 'password123',
      );
      print('Free user created with ID: ${freeUser.user?.uid}');

      // Create Basic user
      print('Creating Basic user...');
      final basicUser = await _auth.createUserWithEmailAndPassword(
        email: 'basic@test.com',
        password: 'password123',
      );
      print('Basic user created with ID: ${basicUser.user?.uid}');

      // Create Professional user
      print('Creating Professional user...');
      final proUser = await _auth.createUserWithEmailAndPassword(
        email: 'pro@test.com',
        password: 'password123',
      );
      print('Professional user created with ID: ${proUser.user?.uid}');

      // Create Enterprise user
      print('Creating Enterprise user...');
      final enterpriseUser = await _auth.createUserWithEmailAndPassword(
        email: 'enterprise@test.com',
        password: 'password123',
      );
      print('Enterprise user created with ID: ${enterpriseUser.user?.uid}');

      // Create companies for each user
      final companies = [
        {
          'name': 'Free Company',
          'userId': freeUser.user?.uid,
          'subscription': SubscriptionTier.free,
        },
        {
          'name': 'Basic Company',
          'userId': basicUser.user?.uid,
          'subscription': SubscriptionTier.basic,
        },
        {
          'name': 'Professional Company',
          'userId': proUser.user?.uid,
          'subscription': SubscriptionTier.professional,
        },
        {
          'name': 'Enterprise Company',
          'userId': enterpriseUser.user?.uid,
          'subscription': SubscriptionTier.enterprise,
        },
      ];

      for (var company in companies) {
        print('Creating company: ${company['name']}');

        // Check if company already exists
        final existingCompany = await _firestore
            .collection('companies')
            .where('name', isEqualTo: company['name'])
            .get();

        if (existingCompany.docs.isNotEmpty) {
          print('Company ${company['name']} already exists, skipping...');
          continue;
        }

        // Create company document
        final companyDoc = await _firestore.collection('companies').add({
          'name': company['name'],
          'createdAt': FieldValue.serverTimestamp(),
          'settings': CompanySettings(
            bankName: 'Test Bank',
            bankAccountNumber: '1234567890',
            bankSwiftCode: 'TEST123',
            currency: 'USD',
            defaultTaxRate: 0.0,
            invoicePrefix: 'INV',
            paymentTerms: 30,
          ).toMap(),
        });
        print('Company document created with ID: ${companyDoc.id}');

        // Create company user relationship
        await _firestore
            .collection('companies')
            .doc(companyDoc.id)
            .collection('users')
            .add({
          'userId': company['userId'],
          'role': UserRole.admin,
          'permissions': CompanyUser.getDefaultPermissions(UserRole.admin),
          'joinedAt': FieldValue.serverTimestamp(),
        });
        print('Company user relationship created');

        // Create subscription
        final subscriptionDoc = await _firestore
            .collection('companies')
            .doc(companyDoc.id)
            .collection('subscription')
            .add({
          'tier': company['subscription'].toString().split('.').last,
          'status': 'active',
          'startDate': FieldValue.serverTimestamp(),
          'endDate': FieldValue.serverTimestamp(),
        });
        print('Subscription created with ID: ${subscriptionDoc.id}');

        // Verify subscription was created
        final subscriptionSnapshot = await subscriptionDoc.get();
        if (!subscriptionSnapshot.exists) {
          throw Exception(
              'Failed to create subscription for ${company['name']}');
        }
        print('Subscription verified for ${company['name']}');
      }

      print('Test user creation completed successfully!');
    } catch (e) {
      print('Error creating test users: $e');
      rethrow;
    }
  }
}
