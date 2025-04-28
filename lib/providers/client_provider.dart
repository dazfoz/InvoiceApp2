import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/firebase_service.dart';

class ClientProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Client> _clients = [];
  Client? _selectedClient;

  List<Client> get clients => _clients;
  Client? get selectedClient => _selectedClient;

  Future<void> loadClients(String companyId) async {
    try {
      _clients = await _firebaseService.getCompanyClients(companyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading clients: $e');
      rethrow;
    }
  }

  Future<Client> createClient(String companyId, Client client) async {
    try {
      print('Creating client in provider with companyId: $companyId');
      final newClient = await _firebaseService.createClient(companyId, client);
      print('Client created in Firebase, adding to local list');
      _clients = [..._clients, newClient];
      notifyListeners();
      print('Client list updated and listeners notified');
      return newClient;
    } catch (e) {
      print('Error in createClient: $e');
      rethrow;
    }
  }

  Future<Client> updateClient(String companyId, Client client) async {
    try {
      final updatedClient =
          await _firebaseService.updateClient(companyId, client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = updatedClient;
      }
      notifyListeners();
      return updatedClient;
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  void setSelectedClient(Client? client) {
    _selectedClient = client;
    notifyListeners();
  }

  void clearClients() {
    _clients = [];
    _selectedClient = null;
    notifyListeners();
  }
}
