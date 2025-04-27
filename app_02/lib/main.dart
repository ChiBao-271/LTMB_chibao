import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:app_02/notesApp/db/auth_api.dart';
import 'package:app_02/notesApp/view/login_screen.dart';
import 'package:app_02/notesApp/view/note_list_screen.dart';
import 'package:app_02/notesApp/mode/theme.dart';
import 'package:app_02/notesApp/mode/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Ứng dụng Quản lý Ghi chú',
            theme: themeProvider.currentTheme,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}