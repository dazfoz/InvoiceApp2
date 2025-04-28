import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice.dart';
import '../models/client.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../widgets/custom_scaffold.dart';
import 'invoice_detail_screen.dart';
import 'create_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final companyProvider = context.read<CompanyProvider>();
    if (companyProvider.currentCompany == null) return;

    try {
      await context
          .read<InvoiceProvider>()
          .loadInvoices(companyProvider.currentCompany!.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoices: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final invoices = invoiceProvider.invoices;

    return CustomScaffold(
      title: 'Invoices',
      selectedIndex: 2, // Invoices is selected
      body: invoices.isEmpty
          ? const Center(
              child: Text('No invoices found'),
            )
          : ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return ListTile(
                  title: Text('Invoice #${invoice.number}'),
                  subtitle: Text(
                      '${invoice.clientId} - \$${invoice.total.toStringAsFixed(2)}'),
                  trailing: Text(invoice.status.toString().split('.').last),
                  onTap: () => _showInvoiceDetails(context, invoice),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateInvoiceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateInvoiceDialog(BuildContext context) async {
    final clientProvider = context.read<ClientProvider>();
    final clients = clientProvider.clients;

    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a client first'),
        ),
      );
      return;
    }

    final clientController = TextEditingController();
    final issueDateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );
    final dueDateController = TextEditingController(
      text:
          DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0],
    );
    final notesController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Invoice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Client',
                ),
                items: clients.map((client) {
                  return DropdownMenuItem(
                    value: client.id,
                    child: Text(client.name),
                  );
                }).toList(),
                onChanged: (value) {
                  clientController.text = value ?? '';
                },
              ),
              TextField(
                controller: issueDateController,
                decoration: const InputDecoration(
                  labelText: 'Issue Date',
                  hintText: 'YYYY-MM-DD',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    issueDateController.text = date.toString().split(' ')[0];
                  }
                },
              ),
              TextField(
                controller: dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'YYYY-MM-DD',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    dueDateController.text = date.toString().split(' ')[0];
                  }
                },
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Enter notes',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final clientId = clientController.text;
              final issueDateStr = issueDateController.text;
              final dueDateStr = dueDateController.text;
              final notes = notesController.text.trim();

              // Parse dates with proper error handling
              final issueDate = DateTime.tryParse(issueDateStr);
              final dueDate = DateTime.tryParse(dueDateStr);

              if (clientId.isEmpty || issueDate == null || dueDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please fill in all required fields with valid dates (YYYY-MM-DD)'),
                  ),
                );
                return;
              }

              final companyProvider = context.read<CompanyProvider>();
              if (companyProvider.currentCompany == null) return;

              try {
                await context.read<InvoiceProvider>().createInvoice(
                      companyProvider.currentCompany!.id,
                      Invoice(
                        id: '',
                        companyId: companyProvider.currentCompany!.id,
                        clientId: clientId,
                        number: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                        issueDate: issueDate,
                        dueDate: dueDate,
                        items: [],
                        notes: notes,
                        status: InvoiceStatus.draft,
                        createdBy: context
                                .read<CompanyProvider>()
                                .currentUserRole
                                ?.userId ??
                            '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating invoice: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInvoiceDetails(
      BuildContext context, Invoice invoice) async {
    // Get the client for this invoice
    final clientProvider = context.read<ClientProvider>();
    final client = clientProvider.clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => Client(
        id: 'unknown',
        companyId: invoice.companyId,
        name: 'Unknown Client',
        email: 'unknown@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Navigate to the detailed invoice screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(
          invoice: invoice,
          client: client,
        ),
      ),
    );
  }
}
