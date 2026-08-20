import 'package:flutter/material.dart';
import 'ui/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('>>> main() reached');
  runApp(const MonsteraApp());
}

class MonsteraApp extends StatelessWidget {
  const MonsteraApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('>>> MonsteraApp.build() reached');
    return MaterialApp(
      title: 'Monstera',
      theme: AppTheme.theme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
