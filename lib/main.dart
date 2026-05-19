import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5961ED),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // straight to login, no splash
    );
  }
}