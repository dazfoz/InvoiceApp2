import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAmDNwRutbxpKIs3n1JiYAeil3FSd_SWtc',
    appId: '1:955679563714:web:336a5fcda7e20a593a805b',
    messagingSenderId: '955679563714',
    projectId: 'freelancer-invoicing-app',
    authDomain: 'freelancer-invoicing-app.firebaseapp.com',
    storageBucket: 'freelancer-invoicing-app.firebasestorage.app',
    measurementId: 'G-S68BTW6FM0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmDNwRutbxpKIs3n1JiYAeil3FSd_SWtc',
    appId: '1:955679563714:android:336a5fcda7e20a593a805b',
    messagingSenderId: '955679563714',
    projectId: 'freelancer-invoicing-app',
    storageBucket: 'freelancer-invoicing-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAmDNwRutbxpKIs3n1JiYAeil3FSd_SWtc',
    appId: '1:955679563714:ios:336a5fcda7e20a593a805b',
    messagingSenderId: '955679563714',
    projectId: 'freelancer-invoicing-app',
    storageBucket: 'freelancer-invoicing-app.firebasestorage.app',
    iosClientId:
        '955679563714-336a5fcda7e20a593a805b.apps.googleusercontent.com',
    iosBundleId: 'com.example.freelanceInvoiceApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAmDNwRutbxpKIs3n1JiYAeil3FSd_SWtc',
    appId: '1:955679563714:macos:336a5fcda7e20a593a805b',
    messagingSenderId: '955679563714',
    projectId: 'freelancer-invoicing-app',
    storageBucket: 'freelancer-invoicing-app.firebasestorage.app',
    iosClientId:
        '955679563714-336a5fcda7e20a593a805b.apps.googleusercontent.com',
    iosBundleId: 'com.example.freelanceInvoiceApp',
  );
}
