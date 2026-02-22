import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('This platform is not configured');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC0P-1QQk4kqlOuOn8WC7F3j8K7QzaTKUo',
    appId: '1:282481364647:android:ebe3d200044bec94265582',
    messagingSenderId: '282481364647',
    projectId: 'un-dia-sin-beber-d61e1',
    storageBucket: 'un-dia-sin-beber-d61e1.appspot.com',
  );
}
