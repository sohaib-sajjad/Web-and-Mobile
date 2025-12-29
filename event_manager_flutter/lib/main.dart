import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/splash.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EventManagerApp());
}

class EventManagerApp extends StatelessWidget {
  const EventManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Event Manager',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SplashScreen(),
    );
  }
}
