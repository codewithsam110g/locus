import 'package:flutter/material.dart';
import 'package:locus/Pages/page_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options:DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://cfggnajivcfnaivqxywi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmZ2duYWppdmNmbmFpdnF4eXdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1NjIwNjUsImV4cCI6MjA1MzEzODA2NX0.IOlJRZmIoPFPXDCtmDG_DO6nnwIU1r8v3LcgzZclHAQ',
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
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            primary: Color.fromRGBO(0, 191, 99, 1),
            secondary: Color.fromRGBO(191, 255, 168, 1),
            tertiary: Colors.white,
            tertiaryContainer: Colors.black),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: PageManager(),
    );
  }
}
