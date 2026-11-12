import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../physical_activity/screens/sports_agenda_screen.dart';
import '../../physical_activity/widgets/sports_agenda_card.dart';
import '../../appointments/models/appointment.dart';
import '../../appointments/screens/appointment_form_screen.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../appointments/services/appointment_provider.dart';
import '../../medications/screens/medications_screen.dart';
import '../../physical_activity/screens/activity_list_screen.dart';
import '../../treatments/models/treatment.dart';
import '../../treatments/repositories/treatment_repository.dart';
import '../../treatments/screens/treatments_screen.dart';
import '../../treatments/utils/date_fr.dart';
import '../models/user.dart';
import 'ai_assistant_screen.dart';
import 'profile_screen.dart';

/// Palette du design system MediTrack (export Stitch « dashboard »).
class _P {
  static const primary = Color(0xFF00685D);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF0058BD);
  static const secondaryFixed = Color(0xFFD8E2FF);
  static const warning = Color(0xFFF4A261);
  static const surface = Color(0xFFF5F7FA);
  static const surfaceContainerLow = Color(0xFFF0F3FF);
  static const surfaceContainer = Color(0xFFE7EEFF);
  static const surfaceContainerHigh = Color(0xFFDEE8FF);
  static const textPrimary = Color(0xFF1D3557);
  static const textSecondary = Color(0xFF6C757D);
  static const onSurfaceVariant = Color(0xFF3D4947);
  static const outline = Color(0xFF6D7A77);
  static const tertiaryDeep = Color(0xFF77321A);

  static const cardShadow = BoxShadow(
    color: Color(0x0D1D3557),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
}

class _T {
  static const h1 = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: _P.textPrimary,
    letterSpacing: -0.4,
  );
  static const h3 = TextStyle(
    fontSize: 18,
    height: 1.33,
    fontWeight: FontWeight.w600,
    color: _P.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
    color: _P.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w400,
    color: _P.textSecondary,
  );
  static const label = TextStyle(
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w500,
    color: _P.textPrimary,
  );
  static const overline = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: _P.primary,
    letterSpacing: 0.7,
  );
}

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TreatmentRepository _repo = TreatmentRepository.instance;
  late Future<_HomeData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppointmentProvider>().loadAll(user: widget.user);
      }
    });
  }

  Future<_HomeData> _load() async {
    final userId = widget.user.id;
    if (userId == null) return _HomeData.empty;
    try {
      final overview = await _repo.overview(userId);
      final now = DateTime.now();
      final today = <_TodayDose>[];
      final logsByTreatment = <int, List<IntakeLog>>{};

      for (final summary in overview.active) {
        final id = summary.treatment.id;
        if (id == null) continue;
        final logs = await _repo.logsOf(id);
        logsByTreatment[id] = logs;
        for (final log in logs) {
          if (_sameDay(log.scheduledAt, now)) {
            today.add(_TodayDose(log: log, treatment: summary.treatment));
          }
        }
      }
      today.sort((a, b) => a.log.scheduledAt.compareTo(b.log.scheduledAt));

      // Prochaine prise : on garde le log correspondant pour pouvoir la valider.
      _NextDose? next;
      for (final summary in overview.active) {
        final at = summary.nextDose;
        if (at == null) continue;
        if (next != null && !at.isBefore(next.at)) continue;
        final logs = logsByTreatment[summary.treatment.id] ?? const <IntakeLog>[];
        IntakeLog? match;
        for (final log in logs) {
          if (log.scheduledAt == at) {
            match = log;
            break;
          }
        }
        // Filet de sécurité : si la date exacte ne correspond pas (arrondi,
        // fuseau...), on prend la première prise encore en attente >= à l'heure.
        match ??= _firstPendingFrom(logs, at);
        next = _NextDose(treatment: summary.treatment, at: at, log: match);
      }

      // Traitement qui se termine dans les 7 prochains jours.
      final dayStart = DateTime(now.year, now.month, now.day);
      _EndingSoon? ending;
      for (final summary in overview.active) {
        final end = summary.treatment.endDate;
        if (end == null) continue;
        final days = end.difference(dayStart).inDays;
        if (days < 0 || days > 7) continue;
        if (ending == null || days < ending.days) {
          ending = _EndingSoon(summary.treatment, days);
        }
      }

      return _HomeData(
        today: today,
        next: next,
        ending: ending,
      );
    } catch (_) {
      // Le tableau de bord reste utilisable même si un module est indisponible.
      return _HomeData.empty;
    }
  }

  Future<void> _refresh() async {
    // Sync treatments from backend first (non-blocking)
    _repo.syncFromBackend();
    final future = _load();
    setState(() {
      _data = future;
    });
    try {
      await context
          .read<AppointmentProvider>()
          .loadAll(user: widget.user);
    } catch (_) {}
    await future;
  }

  Future<void> _takeDose(IntakeLog log) async {
    final logId = log.id;
    if (logId == null) return;
    try {
      await _repo.markLog(logId, IntakeStatus.taken);
      if (!mounted) return;
      setState(() {
        _data = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dose taken at ${fmtTime(DateTime.now())}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error, stack) {
      debugPrint('MediTrack: markLog($logId) a échoué: $error');
      debugPrint('$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to record the dose'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _goAppointments() => _open(AppointmentsScreen(user: widget.user));
  void _goTreatments() => _open(TreatmentsScreen(user: widget.user));
  void _goMedications() => _open(MedicationsScreen(user: widget.user));
  void _goActivity() => _open(const ActivityListScreen());
  void _goSportsAgenda() => _open(SportsAgendaScreen(userId: widget.user.id));
  void _goProfile() => _open(ProfileScreen(user: widget.user));
  void _goAi() => _open(const AiAssistantScreen());
  void _goNewAppointment() => _open(AppointmentFormScreen(user: widget.user));

  @override
  Widget build(BuildContext context) {
    return widget.user.isMedecin ? _buildDoctorHome() : _buildPatientHome();
  }

  // ---------------------------------------------------------------------------
  // Accueil patient (dashboard médicaments / traitements / rendez-vous)
  // ---------------------------------------------------------------------------

  Widget _buildPatientHome() {
    return Scaffold(
      backgroundColor: _P.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppHeader(
              user: widget.user,
              onProfile: _goProfile,
              onAi: _goAi,
            ),
            Expanded(
              child: Consumer<AppointmentProvider>(
                builder: (context, appointments, _) {
                  final upcoming = appointments
                      .appointmentsForPatient(widget.user)
                      .where((a) =>
                          a.startDateTime.isAfter(DateTime.now()) &&
                          !a.status.name.startsWith('CANCELLED'))
                      .toList()
                    ..sort((a, b) =>
                        a.startDateTime.compareTo(b.startDateTime));
                  final next = upcoming.isEmpty ? null : upcoming.first;
                  return FutureBuilder<_HomeData>(
                    future: _data,
                    builder: (context, snapshot) {
                      final loading =
                          snapshot.connectionState == ConnectionState.waiting;
                      final data = snapshot.data ?? _HomeData.empty;
                      return RefreshIndicator(
                        color: _P.primary,
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                          children: [
                            _Greeting(user: widget.user),
                            const SizedBox(height: 16),
                            if (loading)
                              const _LoadingCard()
                            else
                              _MedicationCard(
                                dose: data.next,
                                onTake: _takeDose,
                                onOpenTreatments: _goTreatments,
                              ),
                            const SizedBox(height: 16),
                            _AppointmentCard(
                              appointment: next,
                              onOpen: _goAppointments,
                              onNew: _goNewAppointment,
                            ),
                            const SizedBox(height: 16),
                            SportsAgendaCard(
                              userId: widget.user.id,
                              onOpen: _goSportsAgenda,
                            ),
                            const SizedBox(height: 16),
                            if (!loading)
                              _TreatmentsCard(
                                doses: data.today,
                                onTake: _takeDose,
                                onOpen: _goTreatments,
                              ),
                            if (!loading && data.ending != null) ...[
                              const SizedBox(height: 16),
                              _EndingSoonCard(
                                info: data.ending!,
                                onOpen: _goTreatments,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _HomeNavBar(
        onHome: () {},
        onTreatments: _goTreatments,
        onMedications: _goMedications,
        onAppointments: _goAppointments,
        onActivity: _goActivity,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Accueil médecin (agenda du praticien)
  // ---------------------------------------------------------------------------

  Widget _buildDoctorHome() {
    return Scaffold(
      backgroundColor: _P.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppHeader(
              user: widget.user,
              onProfile: _goProfile,
              onAi: _goAi,
              showAi: false,
            ),
            Expanded(
              child: Consumer<AppointmentProvider>(
                builder: (context, provider, _) {
                  final mine = provider.appointmentsForDoctor(widget.user);
                  final now = DateTime.now();
                  final today = mine
                      .where((a) => _sameDay(a.startDateTime, now))
                      .toList()
                    ..sort((a, b) =>
                        a.startDateTime.compareTo(b.startDateTime));
                  final upcoming = mine
                      .where((a) =>
                          a.startDateTime.isAfter(now) &&
                          !a.isPast)
                      .toList()
                    ..sort((a, b) =>
                        a.startDateTime.compareTo(b.startDateTime));

                  return RefreshIndicator(
                    color: _P.primary,
                    onRefresh: () => provider.loadAll(user: widget.user),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _Greeting(user: widget.user),
                        const SizedBox(height: 16),
                        _DoctorScheduleCard(
                          today: today,
                          onOpenAgenda: _goAppointments,
                        ),
                        const SizedBox(height: 16),
                        _DoctorStatsCard(
                          todayCount: today.length,
                          upcomingCount: upcoming.length,
                          totalCount: mine.length,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _DoctorNavBar(
        onHome: () {},
        onAgenda: _goAppointments,
        onProfile: _goProfile,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Données calculées
// ---------------------------------------------------------------------------

class _NextDose {
  final Treatment treatment;
  final DateTime at;
  final IntakeLog? log;
  const _NextDose({required this.treatment, required this.at, this.log});
}

class _TodayDose {
  final IntakeLog log;
  final Treatment treatment;
  const _TodayDose({required this.log, required this.treatment});

  bool get taken => log.status == IntakeStatus.taken;
}

class _EndingSoon {
  final Treatment treatment;
  final int days;
  const _EndingSoon(this.treatment, this.days);
}

class _HomeData {
  final List<_TodayDose> today;
  final _NextDose? next;
  final _EndingSoon? ending;

  const _HomeData({
    this.today = const [],
    this.next,
    this.ending,
  });

  static const empty = _HomeData();
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Première prise « pending » dont l'heure est >= [from] (la plus proche).
IntakeLog? _firstPendingFrom(List<IntakeLog> logs, DateTime from) {
  IntakeLog? best;
  for (final log in logs) {
    if (log.status != IntakeStatus.pending) continue;
    if (log.scheduledAt.isBefore(from)) continue;
    if (best == null || log.scheduledAt.isBefore(best.scheduledAt)) {
      best = log;
    }
  }
  return best;
}

String _initials(User user) {
  final first = user.prenom.trim();
  final last = user.nom.trim();
  final a = first.isEmpty ? '' : first[0];
  final b = last.isEmpty ? '' : last[0];
  final value = '$a$b'.toUpperCase();
  return value.isEmpty ? '?' : value;
}

String _relativeDose(DateTime at) {
  final now = DateTime.now();
  final diff = at.difference(now);
  if (diff.inMinutes <= 0) return 'now';
  if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
  if (_sameDay(at, now)) return 'at ${fmtTime(at)}';
  if (_sameDay(at, now.add(const Duration(days: 1)))) {
    return 'tomorrow at ${fmtTime(at)}';
  }
  return '${fmtDateLettres(at)} at ${fmtTime(at)}';
}

// ---------------------------------------------------------------------------
// En-tête
// ---------------------------------------------------------------------------

class _AppHeader extends StatelessWidget {
  final User user;
  final VoidCallback onProfile;
  final VoidCallback onAi;
  final bool showAi;

  const _AppHeader({
    required this.user,
    required this.onProfile,
    required this.onAi,
    this.showAi = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _P.surface.withValues(alpha: 0.92),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _P.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: _P.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MediTrack',
                style: TextStyle(
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: _P.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text('Dashboard', style: _T.caption),
            ],
          ),
          const Spacer(),
          if (showAi)
            _IconButton(
              icon: Icons.auto_awesome,
              tooltip: 'MediTrack AI assistant',
              onTap: onAi,
            ),
          _IconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No new notifications'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _Avatar(user: user, onTap: onProfile),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _Avatar({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = user.photoUrl;
    return SizedBox(
      width: 44,
      height: 44,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _P.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: url == null
                ? Center(
                    child: Text(
                      _initials(user),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _P.primary,
                      ),
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        _initials(user),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _P.primary,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        radius: 24,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 24, color: _P.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Salutation
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  final User user;
  const _Greeting({required this.user});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final name = user.prenom.trim().isEmpty ? user.fullName : user.prenom;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: _P.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(fmtDateLettres(now), style: _T.caption),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Hello $name', style: _T.h1),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _P.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [_P.cardShadow],
            ),
            child: const Icon(Icons.eco_outlined, size: 26, color: _P.primary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte 1 — prochain médicament
// ---------------------------------------------------------------------------

class _MedicationCard extends StatelessWidget {
  final _NextDose? dose;
  final Future<void> Function(IntakeLog log) onTake;
  final VoidCallback onOpenTreatments;

  const _MedicationCard({
    required this.dose,
    required this.onTake,
    required this.onOpenTreatments,
  });

  @override
  Widget build(BuildContext context) {
    final next = dose;
    if (next == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Badge(
                  icon: Icons.medication_outlined,
                  color: _P.primary,
                  background: Color(0x1A00685D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXT MEDICATION', style: _T.overline),
                      const SizedBox(height: 2),
                      Text('No scheduled dose', style: _T.h3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Add a treatment to see your upcoming doses here.',
              style: _T.bodySmall,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'View my treatments',
              icon: Icons.list_alt_rounded,
              onTap: onOpenTreatments,
            ),
          ],
        ),
      );
    }

    final treatment = next.treatment;
    final dosage = treatment.medicationDosage;
    final details = [
      treatment.dose,
      if (dosage != null && dosage.trim().isNotEmpty) dosage.trim(),
    ].join(' — ');

    return _Card(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Badge(
                icon: Icons.medication_outlined,
                color: _P.primary,
                background: Color(0x1A00685D),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXT MEDICATION', style: _T.overline),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 4,
                      children: [
                        Text(treatment.medicationName, style: _T.h3),
                        Text(
                          _relativeDose(next.at),
                          style: _T.caption.copyWith(
                            color: _P.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _Pill(
                label: 'Scheduled',
                color: _P.primary,
                background: Color(0x2600685D),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 20,
                  color: _P.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Take $details', style: _T.bodySmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Take now',
            icon: Icons.check_circle_outline_rounded,
            onTap: next.log == null ? null : () => onTake(next.log!),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte 2 — prochain rendez-vous
// ---------------------------------------------------------------------------

class _AppointmentCard extends StatelessWidget {
  final Appointment? appointment;
  final VoidCallback onOpen;
  final VoidCallback onNew;

  const _AppointmentCard({
    required this.appointment,
    required this.onOpen,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final appt = appointment;
    if (appt == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Badge(
                  icon: Icons.calendar_month_rounded,
                  color: _P.secondary,
                  background: _P.secondaryFixed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXT APPOINTMENT', style: _T.overline),
                      const SizedBox(height: 2),
                      Text('No upcoming appointments', style: _T.h3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Schedule your next appointment in a few steps.',
              style: _T.bodySmall,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Book an appointment',
              icon: Icons.add_rounded,
              onTap: onNew,
            ),
          ],
        ),
      );
    }

    final practitioner = appt.practitioner;
    final facility = appt.facility;
    final when = _sameDay(appt.startDateTime, DateTime.now())
        ? 'today at ${fmtTime(appt.startDateTime)}'
        : '${fmtDateLettres(appt.startDateTime)} at ${fmtTime(appt.startDateTime)}';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Badge(
                icon: Icons.calendar_month_rounded,
                color: _P.secondary,
                background: _P.secondaryFixed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXT APPOINTMENT', style: _T.overline),
                    const SizedBox(height: 2),
                    Text(
                      practitioner?.fullName ?? 'Appointment',
                      style: _T.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Pill(
                label: appt.status.labelFr,
                color: appt.status.color,
                background: appt.status.backgroundColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: _P.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appt.reason.isEmpty ? 'Consultation' : appt.reason,
                        style: _T.label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: _P.outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(when, style: _T.caption)),
                  ],
                ),
                if (facility != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: _P.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${facility.name} — ${facility.fullAddress}',
                          style: _T.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Details',
                  icon: Icons.list_alt_rounded,
                  height: 44,
                  fontSize: 13,
                  radius: 8,
                  background: _P.surfaceContainer,
                  foreground: _P.textPrimary,
                  onTap: onOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'New',
                  icon: Icons.add_rounded,
                  height: 44,
                  fontSize: 13,
                  radius: 8,
                  background: _P.surfaceContainer,
                  foreground: _P.textPrimary,
                  onTap: onNew,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte 3 — traitements du jour
// ---------------------------------------------------------------------------

class _TreatmentsCard extends StatelessWidget {
  final List<_TodayDose> doses;
  final Future<void> Function(IntakeLog log) onTake;
  final VoidCallback onOpen;

  const _TreatmentsCard({
    required this.doses,
    required this.onTake,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final done = doses.where((d) => d.taken).length;
    final visible = doses.take(3).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Badge(
                icon: Icons.checklist_rounded,
                color: _P.textPrimary,
                background: _P.surfaceContainerHigh,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s treatments', style: _T.h3),
                    Text(
                      doses.isEmpty
                          ? 'No doses scheduled'
                          : '$done of ${doses.length} completed',
                      style: _T.caption,
                    ),
                  ],
                ),
              ),
              if (doses.isNotEmpty)
                TextButton(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(foregroundColor: _P.primary),
                  child: const Text('View all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (doses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Your doses will appear here once a treatment is active.',
                style: _T.bodySmall,
              ),
            )
          else
            ...visible.map((dose) => _DoseRow(dose: dose, onTake: onTake)),
          if (doses.length > visible.length) ...[
            const SizedBox(height: 4),
            Text(
              '+ ${doses.length - visible.length} more dose(s)',
              style: _T.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _DoseRow extends StatelessWidget {
  final _TodayDose dose;
  final Future<void> Function(IntakeLog log) onTake;

  const _DoseRow({required this.dose, required this.onTake});

  @override
  Widget build(BuildContext context) {
    final taken = dose.taken;
    final time = fmtTime(dose.log.scheduledAt);
    final subtitle = taken
        ? 'Taken${dose.log.takenAt != null ? ' at ${fmtTime(dose.log.takenAt!)}' : ''}'
        : 'Scheduled at $time';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: taken ? null : () => onTake(dose.log),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: taken ? _P.primary : _P.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: taken
                        ? const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: _P.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${dose.treatment.medicationName} — ${dose.treatment.dose}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _T.label.copyWith(
                            color: taken ? _P.textSecondary : _P.textPrimary,
                            fontWeight:
                                taken ? FontWeight.w400 : FontWeight.w500,
                            decoration:
                                taken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(subtitle, style: _T.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte 4 — alerte fin de traitement
// ---------------------------------------------------------------------------

class _EndingSoonCard extends StatefulWidget {
  final _EndingSoon info;
  final VoidCallback onOpen;

  const _EndingSoonCard({required this.info, required this.onOpen});

  @override
  State<_EndingSoonCard> createState() => _EndingSoonCardState();
}

class _EndingSoonCardState extends State<_EndingSoonCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final info = widget.info;
    final days = info.days;
    final label = days == 0
        ? 'ends today'
        : days == 1
            ? 'ends tomorrow'
            : 'ends in $days days';
    final end = info.treatment.endDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_P.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _P.warning.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 24,
                  color: _P.tertiaryDeep,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${info.treatment.medicationName} $label',
                            style: _T.h3.copyWith(fontSize: 16, height: 1.3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const _Pill(
                          label: 'Soon',
                          color: _P.tertiaryDeep,
                          background: Color(0x40F4A261),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      end == null
                          ? 'Treatment ending soon'
                          : 'Last day on ${fmtDate(end)}',
                      style: _T.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'View treatment',
                  icon: Icons.autorenew_rounded,
                  height: 44,
                  fontSize: 13,
                  radius: 8,
                  background: _P.textPrimary,
                  foreground: Colors.white,
                  onTap: widget.onOpen,
                ),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: 'Dismiss',
                height: 44,
                fontSize: 13,
                radius: 8,
                background: Colors.white.withValues(alpha: 0.8),
                foreground: _P.textPrimary,
                onTap: () => setState(() {
                  _dismissed = true;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation basse
// ---------------------------------------------------------------------------

class _HomeNavBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onTreatments;
  final VoidCallback onMedications;
  final VoidCallback onAppointments;
  final VoidCallback onActivity;

  const _HomeNavBar({
    required this.onHome,
    required this.onTreatments,
    required this.onMedications,
    required this.onAppointments,
    required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                active: true,
                onTap: onHome,
              ),
              _NavItem(
                icon: Icons.medication_outlined,
                label: 'Traitements',
                onTap: onTreatments,
              ),
              _NavItem(
                icon: Icons.medication_liquid_rounded,
                label: 'Médicaments',
                onTap: onMedications,
              ),
              _NavItem(
                icon: Icons.calendar_today_rounded,
                label: 'Rendez-vous',
                onTap: onAppointments,
              ),
              _NavItem(
                icon: Icons.monitor_heart_outlined,
                label: 'Activité',
                onTap: onActivity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _P.primary : _P.onSurfaceVariant;
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Briques visuelles partagées
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  final bool accent;

  const _Card({required this.child, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_P.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (accent)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: _P.primary),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(accent ? 22 : 16, 16, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _Badge({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Pill({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double radius;
  final Color background;
  final Color foreground;

  const _ActionButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.height = 52,
    this.fontSize = 16,
    this.radius = 12,
    this.background = _P.primary,
    this.foreground = _P.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: fontSize + 4, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: SizedBox(
        height: 96,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _P.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accueil médecin — briques dédiées
// ---------------------------------------------------------------------------

class _DoctorScheduleCard extends StatelessWidget {
  final List<Appointment> today;
  final VoidCallback onOpenAgenda;

  const _DoctorScheduleCard({
    required this.today,
    required this.onOpenAgenda,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Badge(
                icon: Icons.today_rounded,
                color: _P.secondary,
                background: _P.secondaryFixed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY\'S SCHEDULE', style: _T.overline),
                    const SizedBox(height: 2),
                    Text(
                      today.isEmpty
                          ? 'No appointments today'
                          : '${today.length} appointment(s)',
                      style: _T.h3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (today.isEmpty)
            Text(
              'Your patients\' bookings will appear here.',
              style: _T.bodySmall,
            )
          else
            ...today.take(4).map((a) => _DoctorAppointmentRow(appointment: a)),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Open agenda',
            icon: Icons.calendar_month_rounded,
            onTap: onOpenAgenda,
          ),
        ],
      ),
    );
  }
}

class _DoctorAppointmentRow extends StatelessWidget {
  final Appointment appointment;
  const _DoctorAppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              alignment: Alignment.center,
              child: Text(
                fmtTime(appointment.startDateTime),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _P.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName ?? 'Patient',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.label,
                  ),
                  Text(
                    appointment.reason.isEmpty
                        ? 'Consultation'
                        : appointment.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: appointment.status.labelFr,
              color: appointment.status.color,
              background: appointment.status.backgroundColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorStatsCard extends StatelessWidget {
  final int todayCount;
  final int upcomingCount;
  final int totalCount;

  const _DoctorStatsCard({
    required this.todayCount,
    required this.upcomingCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Badge(
                icon: Icons.insights_rounded,
                color: _P.textPrimary,
                background: _P.surfaceContainerHigh,
              ),
              const SizedBox(width: 8),
              Text('Practice statistics', style: _T.h3),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatBox(label: 'Today', value: '$todayCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(label: 'Upcoming', value: '$upcomingCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(label: 'Total', value: '$totalCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _P.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: _T.caption),
        ],
      ),
    );
  }
}

class _DoctorNavBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onAgenda;
  final VoidCallback onProfile;

  const _DoctorNavBar({
    required this.onHome,
    required this.onAgenda,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: true,
                onTap: onHome,
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Agenda',
                onTap: onAgenda,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
