import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/flavor.dart';

/// Khmer Digital Bank entry point.
///
/// Run with a flavor, e.g.
/// `flutter run --flavor dev --dart-define-from-file=config/env/dev.json`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: currentFlavor.firebaseOptions);
  await configureDependencies();
  runApp(const KhmerBankApp());
}
