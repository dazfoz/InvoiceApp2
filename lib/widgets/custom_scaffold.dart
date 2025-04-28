import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/collapsible_navigation_drawer.dart';
import '../providers/auth_provider.dart' as local_auth;
import '../providers/company_provider.dart';
import '../theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final int selectedIndex;
  final bool isLocked;

  const CustomScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.selectedIndex = 0,
    this.isLocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationState>(context);
    final authProvider = Provider.of<local_auth.AuthProvider>(context);
    final companyProvider = Provider.of<CompanyProvider>(context);

    // Navigation items
    final List<NavigationItem> navigationItems = !isLocked
        ? [
            NavigationItem(
              icon: Icons.home,
              title: 'Home',
              route: '/home',
            ),
            NavigationItem(
              icon: Icons.people,
              title: 'Clients',
              route: '/clients',
            ),
            NavigationItem(
              icon: Icons.receipt,
              title: 'My Invoices',
              route: '/invoices',
            ),
            NavigationItem(
              icon: Icons.business,
              title: 'Company',
              route: '/company',
            ),
            NavigationItem(
              icon: Icons.card_membership,
              title: 'Subscription',
              route: '/subscription',
            ),
            NavigationItem(
              icon: Icons.person,
              title: 'User Details',
              route: '/user-details',
            ),
            NavigationItem(
              icon: Icons.settings,
              title: 'Settings',
              route: '/settings',
            ),
          ]
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Collapsible Navigation Drawer
          CollapsibleNavigationDrawer(
            items: navigationItems,
            header: NavigationDrawerHeader(
              title: 'Freelance Invoice App',
              subtitle: companyProvider.currentCompany?.name ??
                  authProvider.user?.email,
              isExpanded: navProvider.isExpanded,
            ),
            footer: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              leading: Icon(Icons.logout, color: AppTheme.dangerColor),
              title: navProvider.isExpanded
                  ? Text('Logout',
                      style: TextStyle(color: AppTheme.dangerColor))
                  : null,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            selectedIndex: selectedIndex,
            onItemSelected: (index) {
              final route = navigationItems[index].route;
              if (route != null) {
                Navigator.pushReplacementNamed(context, route);
              }
            },
          ),

          // Main content
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: body,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
