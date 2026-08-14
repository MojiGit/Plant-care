import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Enable when google-services.json is added (PC303)
  runApp(const PlantCareApp());
}
