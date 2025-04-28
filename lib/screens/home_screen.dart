import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company_user.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/auth_provider.dart' as local_auth;
import '../providers/navigation_provider.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/collapsible_navigation_drawer.dart';
import '../theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserCompanies();
  }

  Future<void> _loadUserCompanies() async {
    try {
      await context.read<CompanyProvider>().loadUserCompanies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading companies: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();
    final authProvider = context.watch<local_auth.AuthProvider>();
    final currentCompany = companyProvider.currentCompany;

    if (currentCompany == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CustomScaffold(
      title: 'Dashboard',
      selectedIndex: 0, // Home is selected
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to ${currentCompany.name}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You are logged in as ${authProvider.user?.email ?? "Unknown User"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Role: ${currentCompanyUser?.role.toString().split('.').last ?? "Unknown"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        context,
                        'Create Invoice',
                        Icons.add_circle,
                        AppTheme.accentColor,
                        () => Navigator.pushNamed(context, '/create-invoice'),
                      ),
                      _buildActionCard(
                        context,
                        'View Invoices',
                        Icons.receipt,
                        AppTheme.primaryColor,
                        () => Navigator.pushNamed(context, '/invoices'),
                      ),
                      _buildActionCard(
                        context,
                        'Add Client',
                        Icons.person_add,
                        Colors.green,
                        () => Navigator.pushNamed(context, '/create-client'),
                      ),
                      _buildActionCard(
                        context,
                        'View Clients',
                        Icons.people,
                        Colors.orange,
                        () => Navigator.pushNamed(context, '/clients'),
                      ),
                      _buildActionCard(
                        context,
                        'Company Settings',
                        Icons.business,
                        Colors.purple,
                        () => Navigator.pushNamed(context, '/company'),
                      ),
                      _buildActionCard(
                        context,
                        'User Profile',
                        Icons.person,
                        Colors.teal,
                        () => Navigator.pushNamed(context, '/user-details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-invoice');
        },
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CompanyUser? get currentCompanyUser =>
      context.watch<CompanyProvider>().currentUserRole;
}
