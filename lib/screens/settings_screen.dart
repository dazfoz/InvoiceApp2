import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company.dart';
import '../models/subscription.dart';
import '../providers/company_provider.dart';
import '../utils/test_users.dart';
import '../widgets/custom_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _taxNumberController;
  late TextEditingController _registrationNumberController;
  late TextEditingController _vatNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankRoutingController;
  late TextEditingController _bankSwiftController;
  late TextEditingController _bankIbanController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final company = context.read<CompanyProvider>().currentCompany;
    _nameController = TextEditingController(text: company?.name);
    _addressController = TextEditingController(text: company?.address);
    _taxNumberController = TextEditingController(text: company?.taxNumber);
    _registrationNumberController =
        TextEditingController(text: company?.registrationNumber);
    _vatNumberController = TextEditingController(text: company?.vatNumber);
    _phoneController = TextEditingController(text: company?.phone);
    _emailController = TextEditingController(text: company?.email);
    _websiteController = TextEditingController(text: company?.website);
    _bankNameController =
        TextEditingController(text: company?.settings.bankName);
    _bankAccountController =
        TextEditingController(text: company?.settings.bankAccountNumber);
    _bankRoutingController =
        TextEditingController(text: company?.settings.bankRoutingNumber);
    _bankSwiftController =
        TextEditingController(text: company?.settings.bankSwiftCode);
    _bankIbanController =
        TextEditingController(text: company?.settings.bankIban);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final company = context.watch<CompanyProvider>().currentCompany;
    if (company != null) {
      _updateControllers(company);
    }
  }

  void _updateControllers(Company company) {
    _nameController.text = company.name;
    _addressController.text = company.address ?? '';
    _taxNumberController.text = company.taxNumber ?? '';
    _registrationNumberController.text = company.registrationNumber ?? '';
    _vatNumberController.text = company.vatNumber ?? '';
    _phoneController.text = company.phone ?? '';
    _emailController.text = company.email ?? '';
    _websiteController.text = company.website ?? '';
    _bankNameController.text = company.settings.bankName ?? '';
    _bankAccountController.text = company.settings.bankAccountNumber ?? '';
    _bankRoutingController.text = company.settings.bankRoutingNumber ?? '';
    _bankSwiftController.text = company.settings.bankSwiftCode ?? '';
    _bankIbanController.text = company.settings.bankIban ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _registrationNumberController.dispose();
    _vatNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankRoutingController.dispose();
    _bankSwiftController.dispose();
    _bankIbanController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companyProvider = context.read<CompanyProvider>();
      final company = companyProvider.currentCompany;
      if (company == null) return;

      final updatedCompany = company.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        taxNumber: _taxNumberController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        vatNumber: _vatNumberController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        settings: company.settings.copyWith(
          bankName: _bankNameController.text.trim(),
          bankAccountNumber: _bankAccountController.text.trim(),
          bankRoutingNumber: _bankRoutingController.text.trim(),
          bankSwiftCode: _bankSwiftController.text.trim(),
          bankIban: _bankIbanController.text.trim(),
        ),
      );

      await companyProvider.updateCompany(updatedCompany);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSubscriptionInfo(Subscription? subscription) {
    if (subscription == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No active subscription'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Plan: ${subscription.plan}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Status: ${subscription.status}'),
            Text('Start Date: ${subscription.startDate}'),
            if (subscription.endDate != null)
              Text('End Date: ${subscription.endDate}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement upgrade subscription
              },
              child: const Text('Upgrade Plan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyProvider>().currentCompany;

    if (company == null) {
      return const Scaffold(
        body: Center(
          child: Text('No company selected'),
        ),
      );
    }

    // Use CustomScaffold instead of regular Scaffold
    return CustomScaffold(
      title: 'Settings',
      selectedIndex: 5, // Settings is selected
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubscriptionInfo(company.subscription),
              const SizedBox(height: 24),
              const Text(
                'Company Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tax Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _registrationNumberController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vatNumberController,
                decoration: const InputDecoration(
                  labelText: 'VAT Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bank Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankAccountController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankRoutingController,
                decoration: const InputDecoration(
                  labelText: 'Routing Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankSwiftController,
                decoration: const InputDecoration(
                  labelText: 'SWIFT Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankIbanController,
                decoration: const InputDecoration(
                  labelText: 'IBAN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Create Test Users'),
                          content: const Text(
                            'This will create test users for all subscription tiers. '
                            'Do you want to proceed?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      );

                      if (result == true) {
                        await TestUsers.createTestUsers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test users created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating test users: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Create Test Users'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
