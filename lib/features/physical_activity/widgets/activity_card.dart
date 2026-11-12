import 'package:flutter/material.dart';
import '../models/physical_activity.dart';

class ActivityCard extends StatelessWidget {
  final PhysicalActivity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month/$day/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);
    final intensityColor = activity.intensityColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Icône, Type, Date & Heure, Intensité et Menu actions
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      activity.icon,
                      color: kPrimaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.typeLabel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: kNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              _formatDateTime(activity.activityDate),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (activity.activityDate.isAfter(DateTime.now()))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kPrimaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.notifications_active,
                                        size: 11, color: kPrimaryGreen),
                                    SizedBox(width: 3),
                                    Text(
                                      'Reminder -5 min',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge d'intensité
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: intensityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: intensityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      activity.intensityLabel,
                      style: TextStyle(
                        color: intensityColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Menu d'actions (Modifier / Supprimer)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 19, color: kPrimaryGreen),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 19, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 22, thickness: 0.8),
              // Métriques : Durée, Distance, Allure, Vitesse, Calories
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _buildMetric(
                    icon: Icons.timer_outlined,
                    label: '${activity.durationMinutes} min',
                    color: kNavy,
                  ),
                  if (activity.distanceKm != null)
                    _buildMetric(
                      icon: Icons.route_outlined,
                      label: '${activity.distanceKm!.toStringAsFixed(1)} km',
                      color: kPrimaryGreen,
                    ),
                  if (activity.paceLabel != null &&
                      (activity.type.toLowerCase().contains('marche') ||
                          activity.type.toLowerCase().contains('course') ||
                          activity.type.toLowerCase().contains('walk') ||
                          activity.type.toLowerCase().contains('run')))
                    _buildMetric(
                      icon: Icons.speed_rounded,
                      label: activity.paceLabel!,
                      color: const Color(0xFF0058BD),
                    ),
                  if (activity.speedKmh != null &&
                      (activity.type.toLowerCase().contains('vélo') ||
                          activity.type.toLowerCase().contains('velo') ||
                          activity.type.toLowerCase().contains('cycl')))
                    _buildMetric(
                      icon: Icons.speed_rounded,
                      label: '${activity.speedKmh!.toStringAsFixed(1)} km/h',
                      color: const Color(0xFF0058BD),
                    ),
                  if (activity.caloriesBurned != null)
                    _buildMetric(
                      icon: Icons.local_fire_department_outlined,
                      label: '${activity.caloriesBurned} kcal',
                      color: Colors.deepOrange,
                    ),
                ],
              ),
              // Notes éventuelles
              if (activity.notes != null && activity.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.notes!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
