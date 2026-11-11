import 'package:flutter/material.dart';
import '../models/physical_activity.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import 'activity_form_screen.dart';

class ActivityListScreen extends StatefulWidget {
  final int? userId;

  const ActivityListScreen({super.key, this.userId});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final _activityService = ActivityService();
  late Future<List<PhysicalActivity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    setState(() {
      _activitiesFuture = _activityService.getAll(userId: widget.userId);
    });
  }

  Future<void> _refresh() async {
    _loadActivities();
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(userId: widget.userId),
      ),
    );
    if (result == true) {
      _loadActivities();
    }
  }

  Future<void> _navigateToEdit(PhysicalActivity activity) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(
          activityToEdit: activity,
          userId: widget.userId,
        ),
      ),
    );
    if (result == true) {
      _loadActivities();
    }
  }

  Future<void> _confirmDelete(PhysicalActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text(
          'Are you sure you want to delete this ${activity.type.toLowerCase()} session on ${activity.activityDate.day}/${activity.activityDate.month}/${activity.activityDate.year}?',
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted successfully'),
            backgroundColor: Color(0xFF0B6B5D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadActivities();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error while deleting: $e'),
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
          'Physical activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadActivities,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add an activity',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // FutureBuilder conforme au cours (Séance 5, Slide 8)
      body: FutureBuilder<List<PhysicalActivity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          // 1. État de chargement asynchrone
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0B6B5D),
              ),
            );
          }

          // 2. Gestion d'erreur
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 56, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadActivities,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B6B5D),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final activities = snapshot.data ?? [];

          // 3. État vide
          if (activities.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF0B6B5D).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 64,
                        color: Color(0xFF0B6B5D),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No activity recorded',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2540),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Track your fitness every day by adding your walking, running, cycling or swimming sessions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Record my first activity'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B6B5D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Affichage de la liste avec ListView.builder (Séance 3) et RefreshIndicator
          return RefreshIndicator(
            color: const Color(0xFF0B6B5D),
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ActivityCard(
                  activity: activity,
                  onEdit: () => _navigateToEdit(activity),
                  onDelete: () => _confirmDelete(activity),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
