import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
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

  // For Android, add google-services.json to android/app/
  // For iOS, add GoogleService-Info.plist to ios/Runner/
}
