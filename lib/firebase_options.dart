import 'package:firebase_core/firebase_core.dart'
    show
        FirebaseOptions;
import 'package:flutter/foundation.dart'
    show
        defaultTargetPlatform,
        kIsWeb,
        TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'No Web Firebase options configured.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'No iOS Firebase options configured.',
        );
      default:
        throw UnsupportedError(
          'Unsupported platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPx2170xhiYtO464HNKn2Tha6IdjXCgfY',
    appId: '1:801261017559:android:5a4519d91a896209399392',
    messagingSenderId: '801261017559',
    projectId: 'metapifirebase',
    storageBucket: 'metapifirebase.appspot.com',
  );
}
