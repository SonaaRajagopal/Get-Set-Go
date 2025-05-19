import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBGgHHDBrs1vNvQKsUlAlz6zylsGWV_wpc',
        appId: '1:630338788712:web:762c5804735b8832eccadd',
        messagingSenderId: '630338788712',
        projectId: 'expensetracker-17204',
        authDomain: 'expensetracker-17204.firebaseapp.com',
        storageBucket: 'expensetracker-17204.appspot.com',
      );
    }
    if (Platform.isAndroid) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBGgHHDBrs1vNvQKsUlAlz6zylsGWV_wpc',
        appId: '1:630338788712:android:762c5804735b8832eccadd',
        messagingSenderId: '630338788712',
        projectId: 'expensetracker-17204',
        storageBucket: 'expensetracker-17204.appspot.com',
        databaseURL: 'https://expensetracker-17204-default-rtdb.firebaseio.com',
      );
    }
    if (Platform.isIOS) {
      return const FirebaseOptions(
        apiKey: 'YOUR_IOS_API_KEY',
        appId: 'YOUR_IOS_APP_ID',
        messagingSenderId: 'YOUR_IOS_MESSAGING_SENDER_ID',
        projectId: 'YOUR_IOS_PROJECT_ID',
        storageBucket: 'YOUR_IOS_STORAGE_BUCKET',
        databaseURL: 'YOUR_IOS_DATABASE_URL',
        iosClientId: 'YOUR_IOS_CLIENT_ID',
        iosBundleId: 'YOUR_IOS_BUNDLE_ID',
      );
    }
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }
}
