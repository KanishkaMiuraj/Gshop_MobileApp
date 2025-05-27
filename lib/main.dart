import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ynxuanvcfqkicrsdwpar.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlueHVhbnZjZnFraWNyc2R3cGFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyNzU4MTEsImV4cCI6MjA2Mzg1MTgxMX0.CNXlMHRMYyAsZKAl68Pads0M8DxGjMPpHerYgvjTwLU',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce App',
      home: LoginPage(),
    );
  }
}
