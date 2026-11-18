import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';

/// Khmer Digital Bank entry point.
///
/// API base URL: `--dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`.
/// The previous coupon demo screens (lib/coupon, lib/coins, …) are kept in
/// the source tree but are no longer wired into the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const KhmerBankApp());
}
