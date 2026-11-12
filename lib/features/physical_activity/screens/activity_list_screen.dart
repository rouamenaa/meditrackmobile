import 'package:flutter/material.dart';
import '../../auth/services/session.dart';
import '../models/physical_activity.dart';
import '../services/activity_reminder_service.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import '../widgets/daily_motivation_card.dart';
import 'activity_form_screen.dart';
import 'activity_reminder_screen.dart';
import 'activity_recommendations_screen.dart';
import 'sports_agenda_screen.dart';

class ActivityListScreen extends StatefulWidget {
  final String? userId;

  const ActivityListScreen({super.key, this.userId});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final _activityService = ActivityService();
  late Future<List<PhysicalActivity>> _activitiesFuture;
  late Future<ActivityWeeklySummary> _summaryFuture;

  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'Walking',
    'Running',
    'Cycling',
    'Swimming',
    'Other',
  ];

  String? get _effectiveUserId =>
      widget.userId ?? Session.instance.user?.id;

  @override
  void initState() {
    super.initState();
    ActivityService.changeNotifier.addListener(_onActivitiesChanged);
    ActivityReminderService.instance.init();
    _loadData();
  }

  @override
  void dispose() {
    ActivityService.changeNotifier.removeListener(_onActivitiesChanged);
    super.dispose();
  }

  void _onActivitiesChanged() {
    if (mounted) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _activitiesFuture = _activityService
          .getAll(
            userId: _effectiveUserId,
            typeFilter: (_selectedFilter == 'All' || _selectedFilter == 'Tous') ? null : _selectedFilter,
          )
          .then((list) {
            // Synchronise automatiquement les rappels 5 min avant pour les séances futures
            ActivityReminderService.instance.syncUpcomingReminders(list);
            return list;
          });
      _summaryFuture = _activityService.getWeeklySummary(userId: _effectiveUserId);
    });
  }

  Future<void> _refresh() async {
    _loadData();
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(userId: _effectiveUserId),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToEdit(PhysicalActivity activity) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(
          activityToEdit: activity,
          userId: _effectiveUserId,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete(PhysicalActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text(
          'Do you really want to delete this ${activity.typeLabel.toLowerCase()} workout on ${activity.activityDate.month}/${activity.activityDate.day}/${activity.activityDate.year}?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && activity.id != null) {
      try {
        await _activityService.delete(activity.id!);
        // Annule la notification programmée pour cette séance
        await ActivityReminderService.instance.cancelReminderForActivity(activity.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted and reminder cancelled'),
            backgroundColor: Color(0xFF0B6B5D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting activity: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);
    const kBackground = Color(0xFFF8F7FF);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'Physical Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Personalized recommendations',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActivityRecommendationsScreen(),
                ),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Workout agenda',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SportsAgendaScreen(userId: _effectiveUserId),
                ),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Smart reminders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActivityReminderScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New workout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            // 1. Carte Bilan Hebdomadaire (Objectif 150 min OMS)
            FutureBuilder<ActivityWeeklySummary>(
              future: _summaryFuture,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final summary = snap.data!;
                return _buildWeeklySummaryCard(summary);
              },
            ),

            // 2. Carte « Conseil & Motivation du Jour » (API ZenQuotes / Repli Sport-Santé)
            const DailyMotivationCard(),

            // 3. Bannière d'accès aux Recommandations personnalisées
            _buildRecommendationsBanner(),

            // 3. Filtres par type de sport (Barre horizontale de chips)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final filter = _filters[i];
                    final isSelected = _selectedFilter == filter;
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: kPrimaryGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : kNavy,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
                        ),
                      ),
                      showCheckmark: false,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilter = filter;
                          _loadData();
                        });
                      },
                    );
                  },
                ),
              ),
            ),

            // 3. Liste des activités
            FutureBuilder<List<PhysicalActivity>>(
              future: _activitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: kPrimaryGreen),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ActivityCard(
                      activity: activity,
                      onEdit: () => _navigateToEdit(activity),
                      onDelete: () => _confirmDelete(activity),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard(ActivityWeeklySummary summary) {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);
    final percent = (summary.goalProgress * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, color: kPrimaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Weekly summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: summary.goalAchieved
                      ? const Color(0xFFDCFCE7)
                      : kPrimaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary.goalAchieved ? 'Goal reached 🎉' : '$percent% of goal',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: summary.goalAchieved ? const Color(0xFF15803D) : kPrimaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression vers l'objectif 150 min OMS
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.goalProgress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.goalAchieved ? const Color(0xFF12B76A) : kPrimaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Statistiques clés (Durée, Séances, Calories)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Active time',
                value: '${summary.totalMinutes} min',
                subtext: '/ ${summary.weeklyGoalMinutes} min WHO',
              ),
              Container(height: 28, width: 1, color: Colors.grey.shade200),
              _buildStatItem(
                label: 'Workouts',
                value: '${summary.sessionCount}',
                subtext: summary.sessionCount > 1 ? 'workouts' : 'workout',
              ),
              Container(height: 28, width: 1, color: Colors.grey.shade200),
              _buildStatItem(
                label: 'Calories',
                value: '${summary.totalCalories}',
                subtext: 'kcal burned',
                valueColor: Colors.deepOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsBanner() {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: kPrimaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActivityRecommendationsScreen(),
              ),
            );
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: kPrimaryGreen, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalized recommendations',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kNavy,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Activities tailored to your health profile and WHO goals',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: kPrimaryGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String subtext,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0A2540),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kPrimaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 54,
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              (_selectedFilter == 'All' || _selectedFilter == 'Tous')
                  ? 'No activities recorded'
                  : 'No $_selectedFilter workouts',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (_selectedFilter == 'All' || _selectedFilter == 'Tous')
                  ? 'Track your walking, running, cycling, or swimming sessions to maintain consistent physical activity.'
                  : 'Add your first workout in this category.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigateToAdd,
              icon: const Icon(Icons.add),
              label: const Text('Log a workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
