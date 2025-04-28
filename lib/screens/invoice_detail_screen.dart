import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/client.dart';
import '../models/company.dart';
import '../services/pdf_service.dart';
import '../services/email_service.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;
  final Client client;

  const InvoiceDetailScreen({
    Key? key,
    required this.invoice,
    required this.client,
  }) : super(key: key);

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isGeneratingPdf = false;
  bool _isSendingEmail = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final company = Provider.of<CompanyProvider>(context).currentCompany!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoice.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed:
                _isGeneratingPdf ? null : () => _generatePdf(context, company),
          ),
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'Send Email',
            onPressed:
                _isSendingEmail ? null : () => _sendEmail(context, company),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Invoice header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (company.address != null) Text(company.address!),
                    if (company.email != null) Text('Email: ${company.email}'),
                    if (company.phone != null) Text('Phone: ${company.phone}'),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'INVOICE',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text('#${widget.invoice.number}'),
                      const SizedBox(height: 8),
                      Text(
                          'Issue Date: ${_formatDate(widget.invoice.issueDate)}'),
                      Text('Due Date: ${_formatDate(widget.invoice.dueDate)}'),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${widget.invoice.status.toString().split('.').last.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(widget.invoice.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Client information
            Text(
              'Bill To:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(widget.client.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (widget.client.address != null) Text(widget.client.address!),
            Text('Email: ${widget.client.email}'),
            if (widget.client.phone != null)
              Text('Phone: ${widget.client.phone}'),

            const SizedBox(height: 32),

            // Invoice items
            Text(
              'Invoice Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Table header
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Description',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Qty',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Price',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Tax',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Table rows
                    ...widget.invoice.items
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(item.description),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.quantity.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '\$${item.unitPrice.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${item.taxRate.toStringAsFixed(1)}%',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '\$${item.total.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),

                    const Divider(),

                    // Totals
                    Row(
                      children: [
                        const Spacer(flex: 3),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text(
                                      '\$${widget.invoice.subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tax:'),
                                  Text(
                                      '\$${widget.invoice.taxAmount.toStringAsFixed(2)}'),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${widget.invoice.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            if (widget.invoice.notes.isNotEmpty) ...[
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.invoice.notes),
              ),
            ],

            const SizedBox(height: 32),

            // Payment information
            Text(
              'Payment Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (company.settings.bankName != null)
                      Text('Bank: ${company.settings.bankName}'),
                    if (company.settings.bankAccountNumber != null)
                      Text(
                          'Account Number: ${company.settings.bankAccountNumber}'),
                    if (company.settings.bankRoutingNumber != null)
                      Text(
                          'Routing Number: ${company.settings.bankRoutingNumber}'),
                    if (company.settings.bankSwiftCode != null)
                      Text('SWIFT: ${company.settings.bankSwiftCode}'),
                    if (company.settings.bankIban != null)
                      Text('IBAN: ${company.settings.bankIban}'),
                    const SizedBox(height: 8),
                    Text(
                        'Payment Terms: ${company.settings.paymentTerms} days'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isGeneratingPdf
                      ? null
                      : () => _generatePdf(context, company),
                  icon: _isGeneratingPdf
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate PDF'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSendingEmail
                      ? null
                      : () => _sendEmail(context, company),
                  icon: _isSendingEmail
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.email),
                  label: const Text('Send Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.red[300]!;
    }
  }

  Future<void> _generatePdf(BuildContext context, Company company) async {
    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });

    try {
      await PdfService.generateInvoice(
        company: company,
        client: widget.client,
        invoice: widget.invoice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error generating PDF: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, Company company) async {
    setState(() {
      _isSendingEmail = true;
      _errorMessage = null;
    });

    try {
      final emailService = EmailService(
        company: company,
        client: widget.client,
        invoice: widget.invoice,
      );

      final subject = 'Invoice ${widget.invoice.number} from ${company.name}';
      final body = '''
Dear ${widget.client.name},

Please find attached invoice ${widget.invoice.number} for the amount of \$${widget.invoice.total.toStringAsFixed(2)}.

Invoice Details:
- Invoice Number: ${widget.invoice.number}
- Issue Date: ${_formatDate(widget.invoice.issueDate)}
- Due Date: ${_formatDate(widget.invoice.dueDate)}
- Total Amount: \$${widget.invoice.total.toStringAsFixed(2)}

Thank you for your business.

Regards,
${company.name}
''';

      await emailService.sendInvoiceEmail(
        to: widget.client.email,
        subject: subject,
        body: body,
        pdfPath: '', // Will be generated by the service
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error sending email: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }
}
