// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyBt01gERfl321xgUHfJ_lPvqCcLA8AgXug',
    appId: '1:905187884957:web:6aa317778c548516abb974',
    messagingSenderId: '905187884957',
    projectId: 'test-7a857',
    authDomain: 'test-7a857.firebaseapp.com',
    storageBucket: 'test-7a857.appspot.com',
    measurementId: 'G-LCTY3KLQSW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLB0x9723upcJelXNbzgJx-xA4uoMweTM',
    appId: '1:905187884957:android:efa526e96d2f433cabb974',
    messagingSenderId: '905187884957',
    projectId: 'test-7a857',
    storageBucket: 'test-7a857.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8ukme4lrucjWTdU9LSU9QEmn0pIFBKiE',
    appId: '1:905187884957:ios:3ac11c7948ba45b6abb974',
    messagingSenderId: '905187884957',
    projectId: 'test-7a857',
    storageBucket: 'test-7a857.appspot.com',
    iosClientId: '905187884957-jeirfth6pnbmh1kk51lh8cj600odnoav.apps.googleusercontent.com',
    iosBundleId: 'com.example.movein',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD8ukme4lrucjWTdU9LSU9QEmn0pIFBKiE',
    appId: '1:905187884957:ios:3ac11c7948ba45b6abb974',
    messagingSenderId: '905187884957',
    projectId: 'test-7a857',
    storageBucket: 'test-7a857.appspot.com',
    iosClientId: '905187884957-jeirfth6pnbmh1kk51lh8cj600odnoav.apps.googleusercontent.com',
    iosBundleId: 'com.example.movein',
  );
}
