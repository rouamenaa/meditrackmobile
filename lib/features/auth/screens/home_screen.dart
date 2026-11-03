import 'package:flutter/material.dart';
import '../../treatments/screens/treatments_screen.dart';
import '../models/medecin.dart';
import '../models/user.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediTrack')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bonjour ${user.fullName} 👋',
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
              ),
              child: const Text('Mon profil'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _fillTestData(context),
              child: const Text('Remplir des données de test'),
            ),
            const SizedBox(height: 8),
            // MODULE 3.3 TRAITEMENTS (nouveau fichier, aucune autre modif)
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TreatmentsScreen(user: user)),
              ),
              child: const Text('Mes traitements'),
            ),
          ],
        ),
      ),
    );
  }
}