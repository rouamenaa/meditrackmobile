import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../appointments/services/appointment_provider.dart';
import '../../physical_activity/screens/activity_list_screen.dart';
import '../../treatments/screens/treatments_screen.dart';
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
            Text(
              'Bonjour ${user.fullName} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B6B5D),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.calendar_month_rounded),
              label: Consumer<AppointmentProvider>(
                builder: (context, provider, _) {
                  final count = provider.upcomingAppointments.length;
                  return Text(
                    count > 0 ? 'Mes Rendez-vous ($count)' : 'Mes Rendez-vous',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  );
                },
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
              ),
              child: const Text('Mon profil'),
            ),
            const SizedBox(height: 8),
            // MODULE 3.3 TRAITEMENTS
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TreatmentsScreen(user: user)),
              ),
              child: const Text('Mes traitements'),
            ),
            const SizedBox(height: 8),
            // MODULE ACTIVITÉ PHYSIQUE
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActivityListScreen()),
              ),
              child: const Text('Activité physique'),
            ),
          ],
        ),
      ),
    );
  }
}
