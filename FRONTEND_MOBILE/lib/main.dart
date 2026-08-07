import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Ensure the engine binding is ready before any platform channel calls
  // (orientation, system chrome) that run during bootstrap.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ForthPortsApp());
}
