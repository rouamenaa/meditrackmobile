import 'package:flutter/material.dart';
import '../../auth/services/session.dart';
import '../models/physical_activity.dart';
import '../services/activity_reminder_service.dart';
import '../services/activity_service.dart';
import 'activity_form_screen.dart';

/// Écran complet de l'Agenda Sportif (Calendrier mensuel interactif)
///
/// Fonctionnalités :
/// - Calendrier mensuel avec navigation entre mois (précédent / suivant / aujourd'hui)
/// - Indicateurs / épingles visuels sur les jours ayant des séances créées
/// - Distinction claire entre séances passées et séances futures (avec rappel -5 min)
/// - Sélection interactive d'une date et affichage des séances du jour
/// - Affichage détaillé complet d'une séance au clic
/// - Synchronisation temps réel avec SQLite (CRUD)
class SportsAgendaScreen extends StatefulWidget {
  final String? userId;

  const SportsAgendaScreen({super.key, this.userId});

  @override
  State<SportsAgendaScreen> createState() => _SportsAgendaScreenState();
}

class _SportsAgendaScreenState extends State<SportsAgendaScreen> {
  final ActivityService _activityService = ActivityService();
  final ActivityReminderService _reminderService = ActivityReminderService();

  late DateTime _displayedMonth; // Mois en cours de visualisation (1er du mois)
  late DateTime _selectedDay; // Jour actuellement sélectionné

  List<PhysicalActivity> _allActivities = [];
  bool _loading = true;

  static const List<String> _monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  static const List<String> _weekdayNames = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  String? get _effectiveUserId =>
      widget.userId ?? Session.instance.user?.id;

  @override
  void initState() {
    super.initState();
    ActivityService.changeNotifier.addListener(_onActivitiesChanged);
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadActivities();
  }

  @override
  void dispose() {
    ActivityService.changeNotifier.removeListener(_onActivitiesChanged);
    super.dispose();
  }

  void _onActivitiesChanged() {
    if (mounted) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    final list = await _activityService.getAll(userId: _effectiveUserId);
    if (!mounted) return;
    setState(() {
      _allActivities = list;
      _loading = false;
    });
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<PhysicalActivity> _getActivitiesForDay(DateTime day) {
    return _allActivities.where((a) => _isSameDay(a.activityDate, day)).toList()
      ..sort((a, b) => a.activityDate.compareTo(b.activityDate));
  }

  String _formatDateHeader(DateTime date) {
    final day = date.day;
    final month = _monthNames[date.month - 1];
    final year = date.year;
    final weekday = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ][date.weekday - 1];
    return '$weekday $day $month $year';
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _addNewActivityForSelectedDay() async {
    final targetDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      10,
      0,
    );
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(
          userId: _effectiveUserId,
          initialDate: targetDate,
        ),
      ),
    );
    if (result == true) {
      await _loadActivities();
    }
  }

  Future<void> _editActivity(PhysicalActivity activity) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(
          activityToEdit: activity,
          userId: _effectiveUserId,
        ),
      ),
    );
    if (result == true) {
      await _loadActivities();
    }
  }

  Future<void> _deleteActivity(PhysicalActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer cette séance de ${activity.type.toLowerCase()} du ${_formatDateHeader(activity.activityDate)} ?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && activity.id != null) {
      await _activityService.delete(activity.id!);
      await _reminderService.cancelReminderForActivity(activity.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Séance supprimée et rappel annulé'),
          backgroundColor: Color(0xFF00685D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadActivities();
    }
  }

  void _showActivityDetails(PhysicalActivity activity) {
    const kPrimary = Color(0xFF00685D);
    const kTextPrimary = Color(0xFF1D3557);
    final isFuture = activity.activityDate.isAfter(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de drag
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // En-tête : Icône, Type, Statut
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(activity.icon, color: kPrimary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.type,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatDateHeader(activity.activityDate)} à ${_formatTime(activity.activityDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isFuture
                          ? kPrimary.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFuture
                            ? kPrimary.withValues(alpha: 0.3)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFuture
                              ? Icons.alarm_on_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 14,
                          color: isFuture ? kPrimary : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFuture ? 'À venir' : 'Terminée',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isFuture ? kPrimary : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isFuture) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          size: 16, color: kPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rappel programmé 5 min avant (à ${_formatTime(activity.activityDate.subtract(const Duration(minutes: 5)))})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Grille des caractéristiques : Durée, Distance, Intensité, Calories
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDetailTile(
                    icon: Icons.timer_outlined,
                    title: 'Durée',
                    value: '${activity.durationMinutes} min',
                    color: kTextPrimary,
                  ),
                  _buildDetailTile(
                    icon: Icons.route_outlined,
                    title: 'Distance',
                    value: activity.distanceKm != null
                        ? '${activity.distanceKm!.toStringAsFixed(1)} km'
                        : 'Non renseignée',
                    color: kPrimary,
                  ),
                  _buildDetailTile(
                    icon: Icons.bolt_rounded,
                    title: 'Intensité',
                    value: activity.intensity,
                    color: activity.intensityColor,
                  ),
                  if (activity.caloriesBurned != null)
                    _buildDetailTile(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Énergie',
                      value: '${activity.caloriesBurned} kcal',
                      color: Colors.deepOrange,
                    ),
                  if (activity.paceLabel != null)
                    _buildDetailTile(
                      icon: Icons.speed_rounded,
                      title: 'Allure',
                      value: activity.paceLabel!,
                      color: const Color(0xFF0058BD),
                    ),
                  if (activity.speedKmh != null &&
                      activity.type.toLowerCase().contains('vélo'))
                    _buildDetailTile(
                      icon: Icons.speed_rounded,
                      title: 'Vitesse',
                      value: '${activity.speedKmh!.toStringAsFixed(1)} km/h',
                      color: const Color(0xFF0058BD),
                    ),
                ],
              ),

              // Notes du patient
              if (activity.notes != null && activity.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes du patient :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    activity.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Actions Modifier et Supprimer
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _deleteActivity(activity);
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.redAccent),
                      label: const Text('Supprimer',
                          style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _editActivity(activity);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFF00685D);
    const kTextPrimary = Color(0xFF1D3557);
    const kSurface = Color(0xFFF5F7FA);

    final selectedDayActivities = _getActivitiesForDay(_selectedDay);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text(
          'Mon agenda sportif',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _jumpToToday,
            icon: const Icon(Icons.today_rounded, size: 18, color: kPrimary),
            label: const Text(
              'Aujourd\'hui',
              style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: kPrimary),
            tooltip: 'Nouvelle séance',
            onPressed: _addNewActivityForSelectedDay,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadActivities,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // 1. Carte du Calendrier Mensuel
                  _buildCalendarCard(),

                  const SizedBox(height: 16),

                  // 2. En-tête des séances pour le jour sélectionné
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDateHeader(_selectedDay),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: selectedDayActivities.isNotEmpty
                              ? kPrimary.withValues(alpha: 0.12)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${selectedDayActivities.length} ${selectedDayActivities.length > 1 ? 'séances' : 'séance'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selectedDayActivities.isNotEmpty
                                ? kPrimary
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 3. Liste des séances du jour
                  if (selectedDayActivities.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'Aucune séance enregistrée pour cette date.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _addNewActivityForSelectedDay,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Programmer une séance ce jour'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: selectedDayActivities.map((act) {
                        return _buildSessionCard(act);
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarCard() {
    const kPrimary = Color(0xFF00685D);
    const kTextPrimary = Color(0xFF1D3557);

    final monthTitle =
        '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}';

    // Calcul de la grille du mois
    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    // Décalage selon le jour de la semaine (1 = Lundi -> offset 0)
    final startingOffset = firstDayOfMonth.weekday - 1;
    final totalCells = ((startingOffset + daysInMonth) / 7).ceil() * 7;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de navigation du mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: kPrimary,
                tooltip: 'Mois précédent',
                onPressed: _previousMonth,
              ),
              Text(
                monthTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: kPrimary,
                tooltip: 'Mois suivant',
                onPressed: _nextMonth,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // En-têtes des jours de la semaine (Lun - Dim)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdayNames.map((name) {
              return SizedBox(
                width: 36,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startingOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                dayNumber,
              );

              final isSelected = _isSameDay(cellDate, _selectedDay);
              final isToday = _isSameDay(cellDate, DateTime.now());
              final dayActivities = _getActivitiesForDay(cellDate);
              final hasActivities = dayActivities.isNotEmpty;

              final hasFutureActivity =
                  dayActivities.any((a) => a.activityDate.isAfter(DateTime.now()));

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDay = cellDate;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary
                        : (isToday
                            ? kPrimary.withValues(alpha: 0.1)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? kPrimary
                          : (isToday
                              ? kPrimary.withValues(alpha: 0.5)
                              : Colors.transparent),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? kPrimary : kTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Indicateur / Épingle de séances
                      if (hasActivities)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : (hasFutureActivity
                                        ? const Color(0xFF00C853)
                                        : kPrimary),
                              ),
                            ),
                            if (dayActivities.length > 1) ...[
                              const SizedBox(width: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFF00C853), 'Séance à venir (-5 min)'),
              const SizedBox(width: 16),
              _buildLegendDot(kPrimary, 'Séance passée'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildSessionCard(PhysicalActivity activity) {
    const kPrimary = Color(0xFF00685D);
    const kTextPrimary = Color(0xFF1D3557);
    final isFuture = activity.activityDate.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFuture
              ? kPrimary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showActivityDetails(activity),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icône d'activité
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isFuture
                      ? kPrimary.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity.icon,
                  color: isFuture ? kPrimary : Colors.grey.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          activity.type,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activity.intensityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            activity.intensity,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: activity.intensityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 13, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text(
                              _formatTime(activity.activityDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 13, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text(
                              '${activity.durationMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        if (activity.distanceKm != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_outlined,
                                  size: 13, color: kPrimary),
                              const SizedBox(width: 3),
                              Text(
                                '${activity.distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Statut & flèche
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isFuture
                          ? kPrimary.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isFuture ? 'À venir' : 'Terminée',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isFuture ? kPrimary : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
