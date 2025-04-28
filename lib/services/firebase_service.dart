import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/company.dart';
import '../models/company_user.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/subscription.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Company operations
  Future<Company> createCompany(
      String name, String? address, String? taxNumber) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Create the company document
      final companyRef = _firestore.collection('companies').doc();
      final company = Company(
        id: companyRef.id,
        name: name,
        address: address,
        taxNumber: taxNumber,
        settings: CompanySettings(
          currency: 'USD',
          defaultTaxRate: 0.0,
          invoicePrefix: 'INV',
          paymentTerms: 30,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAdmin: true,
      );

      // Set company data
      await companyRef.set(company.toMap());

      // Add user as admin in the members subcollection
      await companyRef.collection('members').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'role': 'admin',
        'permissions': CompanyUser.getDefaultPermissions(UserRole.admin),
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update user document with company reference
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'currentCompanyId': companyRef.id,
        'companies': {
          companyRef.id: {
            'role': 'admin',
            'joinedAt': FieldValue.serverTimestamp(),
          }
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return company;
    } catch (e) {
      print('Error creating company: $e');
      rethrow;
    }
  }

  Future<void> updateCompany(Company company) async {
    try {
      await _firestore
          .collection('companies')
          .doc(company.id)
          .update(company.toMap());
    } catch (e) {
      print('Error updating company: $e');
      rethrow;
    }
  }

  Future<List<Company>> getUserCompanies() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First ensure user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return [];
      }

      // Get all companies where the user is a member
      final companiesSnapshot = await _firestore
          .collection('companies')
          .where('members.${user.uid}.role', isNotEqualTo: null)
          .get();

      final companies = await Future.wait(
        companiesSnapshot.docs.map((doc) async {
          final company = Company.fromFirestore(doc);
          final userRole = await getCompanyUser(company.id);
          return company.copyWith(isAdmin: userRole?.role == UserRole.admin);
        }),
      );

      return companies;
    } catch (e) {
      print('Error loading companies: $e');
      rethrow;
    }
  }

  Future<Company> getCompany(String companyId) async {
    try {
      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();
      if (!companyDoc.exists) throw Exception('Company not found');
      return await Company.fromFirestoreWithSubscription(companyDoc);
    } catch (e) {
      print('Error getting company: $e');
      rethrow;
    }
  }

  // Client operations
  Future<Client> createClient(String companyId, Client client) async {
    try {
      print('Creating client in Firestore for company: $companyId');
      final now = Timestamp.now();

      // First create the document to get its ID
      final docRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('clients')
          .doc();

      // Create the client data with the document ID
      final clientData = {
        ...client.toMap(),
        'id': docRef.id,
        'companyId': companyId,
        'createdAt': now,
        'updatedAt': now,
      };

      // Set the document with the complete data
      await docRef.set(clientData);
      print('Client document created with ID: ${docRef.id}');

      // Return the created client
      return Client.fromFirestore(await docRef.get());
    } catch (e) {
      print('Error in createClient: $e');
      rethrow;
    }
  }

  Future<List<Client>> getCompanyClients(String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('clients')
        .get();
    return snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList();
  }

  Future<Client> updateClient(String companyId, Client client) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('clients')
        .doc(client.id)
        .update(client.toMap());
    return client;
  }

  // Invoice operations
  Future<Invoice> createInvoice(String companyId, Invoice invoice) async {
    final docRef = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invoices')
        .add(invoice.toMap());
    return Invoice.fromFirestore(await docRef.get());
  }

  Future<List<Invoice>> getCompanyInvoices(String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invoices')
        .get();
    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  }

  Future<Invoice> updateInvoice(String companyId, Invoice invoice) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invoices')
        .doc(invoice.id)
        .update(invoice.toMap());
    return invoice;
  }

  // User operations
  Future<CompanyUser?> getCompanyUser(String companyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('members')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;
      return CompanyUser(
        userId: user.uid,
        companyId: companyId,
        role: UserRole.values.firstWhere(
          (e) => e.toString() == 'UserRole.${data['role']}',
          orElse: () => UserRole.member,
        ),
        permissions: List<String>.from(data['permissions'] ?? []),
        joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      print('Error getting company user: $e');
      return null;
    }
  }

  Future<void> addUserToCompany(
      String companyId, String email, UserRole role) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user exists
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) throw Exception('User not found');

      final targetUserId = userQuery.docs.first.id;

      // Add user to company members
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('members')
          .doc(targetUserId)
          .set({
        'role': role.toString().split('.').last,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Add company to user's companies
      final company = await getCompany(companyId);
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('companies')
          .doc(companyId)
          .set(company.toMap());
    } catch (e) {
      print('Error adding user to company: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(
      String companyId, Subscription subscription) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('subscription')
          .doc('current')
          .set(subscription.toMap());
    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  Future<Subscription?> getSubscription(String companyId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('subscription')
          .doc('current')
          .get();

      if (!doc.exists) return null;

      return Subscription.fromFirestore(doc);
    } catch (e) {
      print('Error getting subscription: $e');
      return null;
    }
  }
}
