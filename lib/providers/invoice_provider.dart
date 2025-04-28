import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/firebase_service.dart';

class InvoiceProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Invoice> _invoices = [];
  Invoice? _selectedInvoice;

  List<Invoice> get invoices => _invoices;
  Invoice? get selectedInvoice => _selectedInvoice;

  Future<void> loadInvoices(String companyId) async {
    try {
      _invoices = await _firebaseService.getCompanyInvoices(companyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      rethrow;
    }
  }

  Future<Invoice> createInvoice(String companyId, Invoice invoice) async {
    try {
      final newInvoice =
          await _firebaseService.createInvoice(companyId, invoice);
      _invoices.add(newInvoice);
      notifyListeners();
      return newInvoice;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      rethrow;
    }
  }

  Future<Invoice> updateInvoice(String companyId, Invoice invoice) async {
    try {
      final updatedInvoice =
          await _firebaseService.updateInvoice(companyId, invoice);
      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }
      notifyListeners();
      return updatedInvoice;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      rethrow;
    }
  }

  void setSelectedInvoice(Invoice? invoice) {
    _selectedInvoice = invoice;
    notifyListeners();
  }

  void clearInvoices() {
    _invoices = [];
    _selectedInvoice = null;
    notifyListeners();
  }

  List<Invoice> getInvoicesByStatus(InvoiceStatus status) {
    return _invoices.where((invoice) => invoice.status == status).toList();
  }

  List<Invoice> getOverdueInvoices() {
    final now = DateTime.now();
    return _invoices.where((invoice) {
      return invoice.status == InvoiceStatus.sent &&
          invoice.dueDate.isBefore(now);
    }).toList();
  }
}
