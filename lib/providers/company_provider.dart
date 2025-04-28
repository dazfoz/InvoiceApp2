import 'package:flutter/foundation.dart';
import '../models/company.dart';
import '../models/company_user.dart';
import '../services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Company> _companies = [];
  Company? _currentCompany;
  CompanyUser? _currentUserRole;
  String? _userRole;

  List<Company> get companies => _companies;
  Company? get currentCompany => _currentCompany;
  CompanyUser? get currentUserRole => _currentUserRole;
  String? get userRole => _userRole;

  Future<bool> hasCurrentCompany() async {
    if (_currentCompany != null) return true;

    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // First check if user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'currentCompanyId': null,
        });
        return false;
      }

      final currentCompanyId = userDoc.data()?['currentCompanyId'] as String?;
      if (currentCompanyId == null) return false;

      final companyDoc =
          await _firestore.collection('companies').doc(currentCompanyId).get();
      if (!companyDoc.exists) return false;

      _currentCompany = await Company.fromFirestoreWithSubscription(companyDoc);

      // Get user role in company
      final userRoleDoc = await _firestore
          .collection('companies')
          .doc(currentCompanyId)
          .collection('members')
          .doc(user.uid)
          .get();

      if (!userRoleDoc.exists) {
        // Add user as admin if they don't have a role
        await _firestore
            .collection('companies')
            .doc(currentCompanyId)
            .collection('members')
            .doc(user.uid)
            .set({
          'userId': user.uid, // Added userId field
          'role': 'admin',
          'email': user.email,
          'permissions': CompanyUser.getDefaultPermissions(
              UserRole.admin), // Added permissions
          'joinedAt': FieldValue.serverTimestamp(),
        });
        _userRole = 'admin';
      } else {
        _userRole = userRoleDoc.data()?['role'] as String?;
      }

      _currentUserRole =
          await _firebaseService.getCompanyUser(currentCompanyId);
      return true;
    } catch (e) {
      debugPrint('Error checking current company: $e');
      return false;
    }
  }

  Future<List<Company>> loadCompanies() async {
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

      _companies = await _firebaseService.getUserCompanies();
      notifyListeners();
      return _companies;
    } catch (e) {
      debugPrint('Error loading companies: $e');
      return [];
    }
  }

  Future<void> loadUserCompanies() async {
    try {
      print('Loading user companies...');
      _companies = await _firebaseService.getUserCompanies();
      print('Loaded ${_companies.length} user companies');
      notifyListeners();
    } catch (e) {
      print('Error loading user companies: $e');
      debugPrint('Error loading user companies: $e');
      rethrow;
    }
  }

  Future<void> setCurrentCompany(String companyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First check if company exists
      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();
      if (!companyDoc.exists) {
        throw Exception('Company not found');
      }

      // Get user role in company
      final userRoleDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('members')
          .doc(user.uid)
          .get();

      if (!userRoleDoc.exists) {
        // Add user as admin if they don't have a role
        await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('members')
            .doc(user.uid)
            .set({
          'userId': user.uid, // Added userId field
          'role': 'admin',
          'email': user.email,
          'permissions': CompanyUser.getDefaultPermissions(
              UserRole.admin), // Added permissions
          'joinedAt': FieldValue.serverTimestamp(),
        });
        _userRole = 'admin';
      } else {
        _userRole = userRoleDoc.data()?['role'] as String?;
      }

      // Update user's current company
      await _firestore.collection('users').doc(user.uid).set({
        'currentCompanyId': companyId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Load company data
      _currentCompany = await Company.fromFirestoreWithSubscription(companyDoc);
      _currentUserRole = await _firebaseService.getCompanyUser(companyId);

      print('Current company set to: ${_currentCompany?.name}');
      print('Current user role: ${_currentUserRole?.role}');

      notifyListeners();
    } catch (e, stackTrace) {
      print('Error setting current company: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Company> createCompany(String name, String address) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Create company document directly using the FirebaseService
      final company = await _firebaseService.createCompany(
          name, address, null // taxNumber is null initially
          );

      // Set as current company
      await setCurrentCompany(company.id);

      return company;
    } catch (e, stackTrace) {
      print('Error in createCompany: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateCompany(Company company) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (_userRole != 'admin') {
        throw Exception('Only admins can update company details');
      }

      await _firebaseService.updateCompany(company);
      final index = _companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        _companies[index] = company;
      }
      if (_currentCompany?.id == company.id) {
        _currentCompany = company;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating company: $e');
      rethrow;
    }
  }

  Future<void> addUserToCompany(String email, UserRole role) async {
    if (_currentCompany == null) throw Exception('No company selected');
    try {
      await _firebaseService.addUserToCompany(_currentCompany!.id, email, role);
    } catch (e) {
      debugPrint('Error adding user to company: $e');
      rethrow;
    }
  }

  void clearCurrentCompany() {
    _currentCompany = null;
    _currentUserRole = null;
    notifyListeners();
  }
}
