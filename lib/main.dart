import 'package:flutter/material.dart';
import 'package:meditrackmobile/features/auth/models/user.dart';
import 'package:meditrackmobile/features/auth/repositories/user_repository.dart';
import 'package:meditrackmobile/features/auth/screens/home_screen.dart';
import 'package:meditrackmobile/features/auth/screens/login_screen.dart';


void main() {
  runApp(const MediTrackApp());
}

class MediTrackApp extends StatefulWidget {
  const MediTrackApp({super.key});

  @override
  State<MediTrackApp> createState() => _MediTrackAppState();
}

class _MediTrackAppState extends State<MediTrackApp> {
  late final Future<User?> _restore = UserRepository().restoreSession();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B6B5D),
      ),
      home: FutureBuilder<User?>(
        future: _restore,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snap.data;
          return user == null ? const LoginScreen() : HomeScreen(user: user);
        },
      ),
    );
  }
}