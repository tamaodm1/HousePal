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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBKz_test_web_api_key_placeholder',
    appId: '1:845813029849:web:485ef728eeb38afbb057c8',
    messagingSenderId: '845813029849',
    projectId: 'housepal-e5245',
    authDomain: 'housepal-e5245.firebaseapp.com',
    storageBucket: 'housepal-e5245.appspot.com',
    measurementId: 'G-test_measurement_id',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAxVk2eCBHVIUy2Me1mp5yBIagWYlhQHE',
    appId: '1:845813029849:android:351a0e5ede56333fb057c8',
    messagingSenderId: '845813029849',
    projectId: 'housepal-e5245',
    storageBucket: 'housepal-e5245.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your_ios_api_key_here', // Thay bằng API key từ GoogleService-Info.plist
    appId: 'your_ios_app_id_here', // Thay bằng appId từ GoogleService-Info.plist
    messagingSenderId: '845813029849',
    projectId: 'housepal-e5245',
    storageBucket: 'housepal-e5245.appspot.com',
    iosBundleId: 'your_ios_bundle_id_here', // Thay bằng bundle ID của iOS app
  );
}
