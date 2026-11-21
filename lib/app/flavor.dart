import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show appFlavor;

import '../firebase_options_dev.dart' as dev;
import '../firebase_options_preprod.dart' as preprod;
import '../firebase_options_prod.dart' as prod;
import '../firebase_options_sit.dart' as sit;
import '../firebase_options_uat.dart' as uat;

/// Build environments. The name must match the Android product flavor and
/// the iOS scheme, e.g. `flutter run --flavor uat`.
enum Flavor { dev, sit, uat, preprod, prod }

extension FlavorX on Flavor {
  /// Firebase app registered for this environment in `khmer-flutter-bank`.
  FirebaseOptions get firebaseOptions => switch (this) {
    Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
    Flavor.sit => sit.DefaultFirebaseOptions.currentPlatform,
    Flavor.uat => uat.DefaultFirebaseOptions.currentPlatform,
    Flavor.preprod => preprod.DefaultFirebaseOptions.currentPlatform,
    Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
  };

  bool get isProd => this == Flavor.prod;
}

/// Flavor the app was built with (`--flavor`). Falls back to [Flavor.dev]
/// when run without a flavor.
final Flavor currentFlavor = Flavor.values.firstWhere(
  (f) => f.name == appFlavor,
  orElse: () => Flavor.dev,
);
