import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator and shared preferences
  await setupDependencies();

  runApp(const BrainForgeApp());
}
