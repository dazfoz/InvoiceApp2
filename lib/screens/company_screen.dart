import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../models/company.dart';
import '../widgets/custom_scaffold.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCompany() async {
    final companyProvider =
        Provider.of<CompanyProvider>(context, listen: false);
    final hasCompany = await companyProvider.hasCurrentCompany();

    if (hasCompany && companyProvider.currentCompany != null) {
      final company = companyProvider.currentCompany!;
      _nameController.text = company.name;
      _addressController.text = company.address ?? '';
      _taxNumberController.text = company.taxNumber ?? '';
    }
  }

  Future<void> _saveCompany() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final companyProvider =
            Provider.of<CompanyProvider>(context, listen: false);
        final hasCompany = await companyProvider.hasCurrentCompany();

        if (hasCompany && companyProvider.currentCompany != null) {
          // Update existing company
          final company = Company(
            id: companyProvider.currentCompany!.id,
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            taxNumber: _taxNumberController.text.trim(),
            settings: companyProvider.currentCompany!.settings,
            createdAt: companyProvider.currentCompany!.createdAt,
            updatedAt: DateTime.now(),
            isAdmin: true,
          );

          await companyProvider.updateCompany(company);
        } else {
          // Create new company
          final company = await companyProvider.createCompany(
            _nameController.text.trim(),
            _addressController.text.trim(),
          );

          // Set as current company
          try {
            await companyProvider.setCurrentCompany(company.id);
          } catch (e) {
            print('Error setting current company: $e');
            // Continue anyway since the company was created successfully
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company saved successfully!')),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e, stackTrace) {
        print('Error in _saveCompany: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving company: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Company Settings',
      selectedIndex: 3, // Company is selected
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a company name';
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCompany,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
