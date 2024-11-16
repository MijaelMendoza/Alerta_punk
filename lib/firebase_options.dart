// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyAsRdk_e1gBy1H970wUrOpTZBJsE7I02sU',
    appId: '1:253256561234:web:3fc45dc1c575c422e6e58b',
    messagingSenderId: '253256561234',
    projectId: 'alerta-punk',
    authDomain: 'alerta-punk.firebaseapp.com',
    storageBucket: 'alerta-punk.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnR_XPkYERBZgp_0_TmjiUa49M8-8rWCc',
    appId: '1:253256561234:android:b7314d798ba8128be6e58b',
    messagingSenderId: '253256561234',
    projectId: 'alerta-punk',
    storageBucket: 'alerta-punk.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArypyo9UFVADNOH0lQpo1Vo9acoxMomHg',
    appId: '1:253256561234:ios:ccb3760e9564d63be6e58b',
    messagingSenderId: '253256561234',
    projectId: 'alerta-punk',
    storageBucket: 'alerta-punk.firebasestorage.app',
    iosBundleId: 'com.example.alertaPunk',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyArypyo9UFVADNOH0lQpo1Vo9acoxMomHg',
    appId: '1:253256561234:ios:ccb3760e9564d63be6e58b',
    messagingSenderId: '253256561234',
    projectId: 'alerta-punk',
    storageBucket: 'alerta-punk.firebasestorage.app',
    iosBundleId: 'com.example.alertaPunk',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAsRdk_e1gBy1H970wUrOpTZBJsE7I02sU',
    appId: '1:253256561234:web:8fdd6c5fdb0edf81e6e58b',
    messagingSenderId: '253256561234',
    projectId: 'alerta-punk',
    authDomain: 'alerta-punk.firebaseapp.com',
    storageBucket: 'alerta-punk.firebasestorage.app',
  );
}