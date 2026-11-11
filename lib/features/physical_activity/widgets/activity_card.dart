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

  Color _getIntensityColor(String intensity) {
    switch (intensity.trim().toLowerCase()) {
      case 'low':
        return const Color(0xFF2E7D32); // Vert
      case 'high':
        return const Color(0xFFC62828); // Rouge
      case 'moderate':
      default:
        return const Color(0xFFEF6C00); // Orange
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    final intensityColor = _getIntensityColor(activity.intensity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Icône, Type, Date, Intensité et Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activity.icon,
                    color: kPrimaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.type,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A2540),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(activity.activityDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge d'intensité
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: intensityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: intensityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    activity.intensity,
                    style: TextStyle(
                      color: intensityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Menu d'actions (Modifier / Supprimer)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
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
                              size: 20, color: kPrimaryGreen),
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
                              size: 20, color: Colors.redAccent),
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
            const Divider(height: 24, thickness: 0.8),
            // Métriques : Durée, Distance, Calories
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetric(
                  icon: Icons.timer_outlined,
                  label: '${activity.durationMinutes} min',
                ),
                if (activity.distanceKm != null)
                  _buildMetric(
                    icon: Icons.route_outlined,
                    label: '${activity.distanceKm!.toStringAsFixed(1)} km',
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
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  activity.notes!,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    Color color = const Color(0xFF0B6B5D),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A2540),
          ),
        ),
      ],
    );
  }
}
