import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  late final html.EventListener _messageListener;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _messageListener = (html.Event event) {
        if (event is html.MessageEvent && event.data == 'navigateToLogin') {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      };
      html.window.addEventListener('message', _messageListener);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      html.window.removeEventListener('message', _messageListener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text('This screen is only available on web'),
        ),
      );
    }

    return const Scaffold(
      body: HtmlElementView(
        viewType: 'website-iframe',
      ),
    );
  }
}
