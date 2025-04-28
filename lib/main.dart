import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.io) 'dart:io' show window;
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/invoice_detail_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/create_client_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/company_screen.dart';
import 'screens/website_screen.dart';
import 'screens/user_details_screen.dart';
import 'screens/company_logo_screen.dart';
import 'screens/subscription_spoof_screen.dart';

import 'providers/auth_provider.dart' as local_auth;
import 'providers/client_provider.dart';
import 'providers/company_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/navigation_provider.dart';

import 'models/invoice.dart';
import 'models/client.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Initialize Firebase for web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyAmDNwRutbxpKIs3n1JiYAeil3FSd_SWtc",
          authDomain: "freelancer-invoicing-app.firebaseapp.com",
          projectId: "freelancer-invoicing-app",
          storageBucket: "freelancer-invoicing-app.firebasestorage.app",
          messagingSenderId: "955679563714",
          appId: "1:955679563714:web:336a5fcda7e20a593a805b",
          measurementId: "G-S68BTW6FM0"),
    );

    // Set up the iframe
    final iframe = html.IFrameElement()
      ..src = 'website/index.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Register the iframe view factory
    ui.platformViewRegistry
        .registerViewFactory('website-iframe', (int viewId) => iframe);

    // Check if we're being redirected to login
    if (html.window.location.hash == '#/login') {
      html.window.history.pushState({}, '', '/');
    }
  } else {
    await Firebase.initializeApp();
  }

  // Create and initialize the navigation provider
  final navigationProvider = NavigationState();
  await navigationProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<local_auth.AuthProvider>(
          create: (context) => local_auth.AuthProvider(),
        ),
        ChangeNotifierProvider<NavigationState>(
          create: (context) => navigationProvider,
        ),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppThemeProvider(
      child: MaterialApp(
        title: 'Bolt Invoice',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthenticationWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
          '/create-invoice': (context) => const CreateInvoiceScreen(),
          '/invoices': (context) => const InvoicesScreen(),
          '/invoice-detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return InvoiceDetailScreen(
              invoice: args['invoice'] as Invoice,
              client: args['client'] as Client,
            );
          },
          '/clients': (context) => const ClientsScreen(),
          '/create-client': (context) => const CreateClientScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/subscription': (context) => const SubscriptionScreen(),
          '/company': (context) => const CompanyScreen(),
          '/user-details': (context) => const UserDetailsScreen(),
          '/company-logo': (context) => const CompanyLogoScreen(),
          '/subscription-spoof': (context) => const SubscriptionSpoofScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                  builder: (context) => const LoginScreen());
            case '/register':
              return MaterialPageRoute(
                  builder: (context) => const RegistrationScreen());
            case '/home':
              return MaterialPageRoute(
                  builder: (context) => const HomeScreen());
            case '/company':
              return MaterialPageRoute(
                  builder: (context) => const CompanyScreen());
            default:
              return MaterialPageRoute(
                  builder: (context) => const WebsiteScreen());
          }
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        User? user = snapshot.data;
        if (user == null) {
          return const WebsiteScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error: ${userSnapshot.error}'),
                ),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final Map<String, dynamic> userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              if (userData.containsKey('companyId') &&
                  userData['companyId'] != null) {
                return const HomeScreen();
              }
            }
            return const CompanyScreen();
          },
        );
      },
    );
  }
}
