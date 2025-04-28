import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../providers/company_provider.dart';
import '../widgets/custom_scaffold.dart';
import 'create_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final companyProvider = context.read<CompanyProvider>();
    if (companyProvider.currentCompany == null) return;

    try {
      await context
          .read<ClientProvider>()
          .loadClients(companyProvider.currentCompany!.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();
    final clients = clientProvider.clients;

    return CustomScaffold(
      title: 'Clients',
      selectedIndex: 1, // Clients is selected
      body: clients.isEmpty
          ? const Center(
              child: Text('No clients found'),
            )
          : ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(client.name),
                  subtitle: Text(client.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditClientDialog(context, client),
                  ),
                  onTap: () => _showClientDetails(context, client),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateClientDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateClientDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final taxNumberController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter client name',
                ),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter client email',
                ),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  hintText: 'Enter client phone',
                ),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'Enter client address',
                ),
              ),
              TextField(
                controller: taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tax Number (Optional)',
                  hintText: 'Enter tax number',
                ),
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
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();
              final taxNumber = taxNumberController.text.trim();

              if (name.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter name and email'),
                  ),
                );
                return;
              }

              final companyProvider = context.read<CompanyProvider>();
              if (companyProvider.currentCompany == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No company selected'),
                  ),
                );
                return;
              }

              try {
                print('Creating client with data: name=$name, email=$email');
                final client = Client(
                  id: '', // This will be set by Firestore
                  companyId: companyProvider.currentCompany!.id,
                  name: name,
                  email: email,
                  phone: phone.isEmpty ? null : phone,
                  address: address.isEmpty ? null : address,
                  taxNumber: taxNumber.isEmpty ? null : taxNumber,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await context.read<ClientProvider>().createClient(
                      companyProvider.currentCompany!.id,
                      client,
                    );

                print('Client created successfully');
                if (context.mounted) {
                  Navigator.pop(context);
                  await _loadClients(); // Refresh the client list
                }
              } catch (e) {
                print('Error creating client: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating client: $e')),
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

  Future<void> _showEditClientDialog(
      BuildContext context, Client client) async {
    final nameController = TextEditingController(text: client.name);
    final emailController = TextEditingController(text: client.email);
    final phoneController = TextEditingController(text: client.phone);
    final addressController = TextEditingController(text: client.address);
    final taxNumberController = TextEditingController(text: client.taxNumber);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter client name',
                ),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter client email',
                ),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  hintText: 'Enter client phone',
                ),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'Enter client address',
                ),
              ),
              TextField(
                controller: taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tax Number (Optional)',
                  hintText: 'Enter tax number',
                ),
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
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();
              final taxNumber = taxNumberController.text.trim();

              if (name.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter name and email'),
                  ),
                );
                return;
              }

              final companyProvider = context.read<CompanyProvider>();
              if (companyProvider.currentCompany == null) return;

              try {
                await context.read<ClientProvider>().updateClient(
                      companyProvider.currentCompany!.id,
                      client.copyWith(
                        name: name,
                        email: email,
                        phone: phone.isEmpty ? null : phone,
                        address: address.isEmpty ? null : address,
                        taxNumber: taxNumber.isEmpty ? null : taxNumber,
                      ),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating client: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClientDetails(BuildContext context, Client client) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${client.email}'),
              if (client.phone != null) Text('Phone: ${client.phone}'),
              if (client.address != null) Text('Address: ${client.address}'),
              if (client.taxNumber != null)
                Text('Tax Number: ${client.taxNumber}'),
              const SizedBox(height: 16),
              Text(
                'Created: ${client.createdAt.toString().split('.').first}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Updated: ${client.updatedAt.toString().split('.').first}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
