import 'package:flutter/material.dart';
import '../models/physical_activity.dart';

const _kPrimaryGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);

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
    final intensityColor = activity.intensityColor;
    final isUpcoming = activity.activityDate.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : Icône, Nom, Date, Intensité & Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _kPrimaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activity.icon,
                        color: _kPrimaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity.typeLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _kNavy,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: intensityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: intensityColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  activity.intensityLabel,
                                  style: TextStyle(
                                    color: intensityColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                _formatDateTime(activity.activityDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (isUpcoming)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _kPrimaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.notifications_active_rounded,
                                        size: 11,
                                        color: _kPrimaryGreen,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Reminder -5m',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _kPrimaryGreen,
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
                    // Menu actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: Colors.grey.shade500, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                                  size: 18, color: _kPrimaryGreen),
                              SizedBox(width: 10),
                              Text('Edit', style: TextStyle(fontSize: 13.5)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Rangée des métriques avec badges modernes
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildMetricBadge(
                      icon: Icons.timer_outlined,
                      label: '${activity.durationMinutes} min',
                      color: _kNavy,
                      bgColor: const Color(0xFFF1F5F9),
                    ),
                    if (activity.distanceKm != null)
                      _buildMetricBadge(
                        icon: Icons.route_outlined,
                        label: '${activity.distanceKm!.toStringAsFixed(1)} km',
                        color: _kPrimaryGreen,
                        bgColor: _kPrimaryGreen.withValues(alpha: 0.08),
                      ),
                    if (activity.paceLabel != null &&
                        (activity.type.toLowerCase().contains('marche') ||
                            activity.type.toLowerCase().contains('course') ||
                            activity.type.toLowerCase().contains('walk') ||
                            activity.type.toLowerCase().contains('run')))
                      _buildMetricBadge(
                        icon: Icons.speed_rounded,
                        label: activity.paceLabel!,
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    if (activity.speedKmh != null &&
                        (activity.type.toLowerCase().contains('vélo') ||
                            activity.type.toLowerCase().contains('velo') ||
                            activity.type.toLowerCase().contains('cycl')))
                      _buildMetricBadge(
                        icon: Icons.speed_rounded,
                        label: '${activity.speedKmh!.toStringAsFixed(1)} km/h',
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    if (activity.caloriesBurned != null)
                      _buildMetricBadge(
                        icon: Icons.local_fire_department_rounded,
                        label: '${activity.caloriesBurned} kcal',
                        color: const Color(0xFFEA580C),
                        bgColor: const Color(0xFFFFF7ED),
                      ),
                  ],
                ),

                // Notes éventuelles
                if (activity.notes != null &&
                    activity.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activity.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.3,
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
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
