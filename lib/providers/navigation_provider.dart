import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationState with ChangeNotifier {
  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isExpanded = prefs.getBool('nav_expanded') ?? true;
    notifyListeners();
  }

  Future<void> toggleExpanded() async {
    _isExpanded = !_isExpanded;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nav_expanded', _isExpanded);
    notifyListeners();
  }

  Future<void> setExpanded(bool expanded) async {
    if (_isExpanded != expanded) {
      _isExpanded = expanded;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nav_expanded', _isExpanded);
      notifyListeners();
    }
  }
}
