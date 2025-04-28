import '../services/pdf_service.dart';
import '../models/invoice.dart';
import '../models/client.dart';
import '../models/company.dart';

class EmailService {
  final Company company;
  final Client client;
  final Invoice invoice;

  EmailService({
    required this.company,
    required this.client,
    required this.invoice,
  });

  Future<void> sendInvoiceEmail({
    required String to,
    required String subject,
    required String body,
    required String pdfPath,
  }) async {
    try {
      await PdfService.generateInvoice(
        company: company,
        client: client,
        invoice: invoice,
      );

      // TODO: Implement email sending
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }
}
