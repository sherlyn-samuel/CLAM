import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // ← ADD THIS

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CLAM',
      home: const LoginScreen(), 
    );
  }
}