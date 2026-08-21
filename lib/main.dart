import 'package:flutter/material.dart';
import 'ui/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MonsteraApp());
}

class MonsteraApp extends StatelessWidget {
  const MonsteraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monstera',
      theme: AppTheme.theme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
