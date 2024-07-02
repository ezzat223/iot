import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:icu/firebase_options.dart';
import 'package:icu/pages/details/details.dart';
import 'package:icu/pages/home/home.dart';
import 'package:icu/pages/signup/login.dart';
import 'package:icu/pages/signup/signup.dart';
import 'package:icu/pages/patient/patient.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      theme: ThemeData(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => LoginPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => Register(),
        '/home': (context) => HomePage(username: '', email: ''),
        '/details': (context) => DetailsPage(),
        '/patient': (context) => PatientPage(username: '', watchId: '',),
      },
      initialRoute: '/',
    );
  }
}
