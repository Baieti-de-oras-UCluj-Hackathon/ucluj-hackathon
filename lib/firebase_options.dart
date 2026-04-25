// GENERATED: run `dart pub global run flutterfire_cli:flutterfire configure`
// in this project and replace. Values below are placeholders for CI/analyze.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4-cjDaE-WqzTIidMSkhbnACmpe9frnyk',
    appId: '1:787122268127:web:c6abda9d391af42227866a',
    messagingSenderId: '787122268127',
    projectId: 'uhack26-8050e',
    authDomain: 'uhack26-8050e.firebaseapp.com',
    storageBucket: 'uhack26-8050e.firebasestorage.app',
    measurementId: 'G-X8B39P76N5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'replace-me',
    appId: '1:0:android:0',
    messagingSenderId: '0',
    projectId: 'umbraro-dev',
    storageBucket: 'umbraro-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'replace-me',
    appId: '1:0:ios:0',
    messagingSenderId: '0',
    projectId: 'umbraro-dev',
    storageBucket: 'umbraro-dev.firebasestorage.app',
    iosBundleId: 'ro.umbraro.app',
  );
}