// Generate this file using: flutterfire configure
// This is a placeholder - replace with your actual Firebase configuration

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace these with your actual Firebase project configuration
  // Run 'flutterfire configure' in your terminal to auto-generate this file

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBb4Y03aSPSm-qU08KUmc8UDtD9xKr_enw',
    appId: '1:413213640360:android:0c64fda85783738ed0e49d',
    messagingSenderId: '413213640360',
    projectId: 'for-a-debt',
    storageBucket: 'for-a-debt.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuW7flbrJ-HcIfaKEBe6Qeo6eD-YCfFYQ',
    appId: '1:413213640360:ios:e2eb7f1866ff1289d0e49d',
    messagingSenderId: '413213640360',
    projectId: 'for-a-debt',
    storageBucket: 'for-a-debt.firebasestorage.app',
    iosBundleId: 'com.example.mydebt',
  );
}
