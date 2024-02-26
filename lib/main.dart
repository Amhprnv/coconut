import 'package:coconut/firebase_options.dart';
import 'package:coconut/screens/home_page.dart';
import 'package:coconut/screens/result_page.dart';
import 'package:coconut/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xff0E1D3E),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xff0E1D3E),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        textTheme: TextTheme(
          displayMedium: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          displaySmall: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          displayLarge: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
