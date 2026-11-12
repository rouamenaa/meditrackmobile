import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/models/user.dart';
import '../models/appointment.dart';
import '../services/appointment_provider.dart';
import '../widgets/appointment_card.dart';
import '../widgets/month_calendar.dart';
import 'appointment_form_screen.dart';

const _kGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);
const _kBackground = Color(0xFFF8F7FF);

/// Module de gestion des rendez-vous.
///
/// - Patient : réserve ses rendez-vous et consulte uniquement les siens
///   (onglets Upcoming / History).
/// - Médecin : consulte l'agenda de ses rendez-vous dans un calendrier mensuel.
class AppointmentsScreen extends StatefulWidget {
  final User user;
  const AppointmentsScreen({super.key, required this.user});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppointmentProvider>().loadAll(user: widget.user);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openForm([Appointment? appointment]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentFormScreen(
          user: widget.user,
          appointment: appointment,
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Appointment appointment) {
    final other = widget.user.isMedecin
        ? (appointment.patientName ?? 'this patient')
        : (appointment.practitioner?.fullName ?? 'this doctor');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this appointment?'),
        content: Text('Do you really want to delete the appointment with $other?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.user.isMedecin ? _buildDoctorAgenda() : _buildPatientList();
  }

  // ===========================================================================
  // VUE PATIENT — liste Upcoming / History + réservation
  // ===========================================================================

  Widget _buildPatientList() {
    final provider = context.watch<AppointmentProvider>();
    final mine = provider.appointmentsForPatient(widget.user);
    final now = DateTime.now();
    final upcoming = mine
        .where((a) => a.startDateTime.isAfter(now) && !_isCancelled(a))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    final past = mine
        .where((a) => !a.startDateTime.isAfter(now) || _isCancelled(a))
        .toList()
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'My Appointments',
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
              child: _TabLabel(
                text: 'Upcoming',
                count: upcoming.length,
                color: _kGreen,
              ),
            ),
            Tab(
              child: _TabLabel(
                text: 'History',
                count: past.length,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Appointment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openForm(),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : RefreshIndicator(
              color: _kGreen,
              onRefresh: () => provider.loadAll(user: widget.user),
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

  bool _isCancelled(Appointment a) =>
      a.status.name.startsWith('CANCELLED');

  Widget _buildList(List<Appointment> list, AppointmentProvider provider) {
    if (list.isEmpty) {
      return _buildEmptyState(
        'No appointments in this section',
        'Schedule your medical consultations in just a few clicks.',
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
            key: ValueKey(appointment.remoteId ?? appointment.id ?? index),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(context, appointment),
            onDismissed: (_) {
              if (appointment.id != null || appointment.remoteId != null) {
                provider.deleteAppointment(appointment, user: widget.user);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment deleted')),
                );
              }
            },
            background: _deleteBackground(),
            child: AppointmentCard(
              appointment: appointment,
              canChangeStatus: widget.user.isMedecin,
              onTap: () => _openForm(appointment),
              onDelete: () {
                if (appointment.id != null || appointment.remoteId != null) {
                  provider.deleteAppointment(appointment, user: widget.user);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment deleted')),
                  );
                }
              },
              onStatusChanged: (newStatus) {
                if (appointment.id != null || appointment.remoteId != null) {
                  provider.changeStatus(
                    appointment,
                    newStatus,
                    user: widget.user,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // VUE MÉDECIN — calendrier + rendez-vous du jour sélectionné
  // ===========================================================================

  Widget _buildDoctorAgenda() {
    final provider = context.watch<AppointmentProvider>();
    final mine = provider.appointmentsForDoctor(widget.user);

    final today = MonthCalendar.dayOnly(DateTime.now());
    final selectedDay = _selectedDay ?? today;

    int eventsOn(DateTime day) => mine
        .where((a) => _sameDay(a.startDateTime, day) && !_isCancelled(a))
        .length;

    final dayAppointments = mine
        .where((a) => _sameDay(a.startDateTime, selectedDay))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(fontWeight: FontWeight.bold, color: _kNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kNavy,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : RefreshIndicator(
              color: _kGreen,
              onRefresh: () => provider.loadAll(user: widget.user),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _SpecialtyBanner(user: widget.user, total: mine.length),
                  const SizedBox(height: 16),
                  MonthCalendar(
                    month: _visibleMonth,
                    selectedDay: selectedDay,
                    eventsOn: eventsOn,
                    onSelectDay: (day) =>
                        setState(() => _selectedDay = day),
                    onPreviousMonth: () => setState(() {
                      _visibleMonth = DateTime(
                          _visibleMonth.year, _visibleMonth.month - 1, 1);
                    }),
                    onNextMonth: () => setState(() {
                      _visibleMonth = DateTime(
                          _visibleMonth.year, _visibleMonth.month + 1, 1);
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Appointments on ${_formatFullDate(selectedDay)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (dayAppointments.isEmpty)
                    _DayEmpty()
                  else
                    for (final appointment in dayAppointments)
                      AppointmentCard(
                        appointment: appointment,
                        showPatient: true,
                        canChangeStatus: true,
                        onTap: () {},
                        onDelete: () {
                          if (appointment.id != null ||
                              appointment.remoteId != null) {
                            provider.deleteAppointment(
                              appointment,
                              user: widget.user,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Appointment deleted')),
                            );
                          }
                        },
                        onStatusChanged: (newStatus) {
                          if (appointment.id != null ||
                              appointment.remoteId != null) {
                            provider.changeStatus(
                              appointment,
                              newStatus,
                              user: widget.user,
                            );
                          }
                        },
                      ),
                ],
              ),
            ),
    );
  }

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ===========================================================================
  // Briques communes
  // ===========================================================================

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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Book an appointment'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
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
            'Delete',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final int count;
  final Color color;

  const _TabLabel({required this.text, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bandeau d'information affiché au médecin (spécialité + nombre de RDV).
class _SpecialtyBanner extends StatelessWidget {
  final User user;
  final int total;

  const _SpecialtyBanner({required this.user, required this.total});

  @override
  Widget build(BuildContext context) {
    final specialty = (user.specialite ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD5E7E4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_outlined, color: _kGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialty.isEmpty ? 'All specialties' : specialty,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialty.isEmpty
                      ? '$total appointment(s) in the agenda'
                      : '$total appointment(s) for your specialty',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No appointments on this day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
