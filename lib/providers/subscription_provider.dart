import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/firebase_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  Subscription? _currentSubscription;
  bool _isLoading = false;

  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;

  Future<void> loadSubscription(String companyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSubscription = await _firebaseService.getSubscription(companyId);
    } catch (e) {
      debugPrint('Error loading subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubscription(
      String companyId, Subscription subscription) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.updateSubscription(companyId, subscription);
      _currentSubscription = subscription;
    } catch (e) {
      debugPrint('Error updating subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
