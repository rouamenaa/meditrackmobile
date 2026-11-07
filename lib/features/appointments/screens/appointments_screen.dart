import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/appointment_provider.dart';
import '../widgets/appointment_card.dart';
import 'appointment_form_screen.dart';

const _kGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);
const _kBackground = Color(0xFFF8F7FF);

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openForm([Appointment? appointment]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentFormScreen(appointment: appointment),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Appointment appointment) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le rendez-vous ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le rendez-vous avec ${appointment.practitioner?.fullName ?? "ce médecin"} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String sub) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEFFD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 48,
                      color: _kGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sub,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Prendre un rendez-vous'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Appointment> list, AppointmentProvider provider) {
    if (list.isEmpty) {
      return _buildEmptyState(
        'Aucun rendez-vous dans cette section',
        'Planifiez vos consultations médicales en quelques clics.',
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      thickness: 5,
      radius: const Radius.circular(8),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        itemCount: list.length,
        itemBuilder: (ctx, index) {
        final appointment = list[index];

        return Dismissible(
          key: ValueKey(appointment.id ?? index),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(context, appointment),
          onDismissed: (_) {
            if (appointment.id != null) {
              provider.deleteAppointment(appointment.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rendez-vous supprimé')),
              );
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          child: AppointmentCard(
            appointment: appointment,
            onTap: () => _openForm(appointment),
            onDelete: () {
              if (appointment.id != null) {
                provider.deleteAppointment(appointment.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rendez-vous supprimé')),
                );
              }
            },
            onStatusChanged: (newStatus) {
              if (appointment.id != null) {
                provider.changeStatus(appointment.id!, newStatus);
              }
            },
          ),
        );
      },
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final upcoming = provider.upcomingAppointments;
    final past = provider.pastAppointments;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'Mes Rendez-vous',
          style: TextStyle(fontWeight: FontWeight.bold, color: _kNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kNavy,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kGreen,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: _kGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('À venir'),
                  if (upcoming.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${upcoming.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Historique'),
                  if (past.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${past.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau RDV', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openForm(),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : RefreshIndicator(
              color: _kGreen,
              onRefresh: () => provider.loadAll(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(upcoming, provider),
                  _buildList(past, provider),
                ],
              ),
            ),
    );
  }
}
