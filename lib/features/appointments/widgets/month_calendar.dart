import 'package:flutter/material.dart';

const _kGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthLabels = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Calendrier mensuel maison (sans dépendance externe).
///
/// Affiche un mois, met en évidence le jour sélectionné et signale d'un point
/// les jours contenant des rendez-vous. La navigation mois précédent / suivant
/// est gérée par les callbacks [onPreviousMonth] / [onNextMonth].
class MonthCalendar extends StatelessWidget {
  /// Mois affiché (jour ignoré).
  final DateTime month;

  /// Jour actuellement sélectionné (jour ignoré si null).
  final DateTime? selectedDay;

  /// Renvoie le nombre de rendez-vous pour un jour donné.
  final int Function(DateTime day) eventsOn;

  /// Appelé quand l'utilisateur touche un jour.
  final ValueChanged<DateTime> onSelectDay;

  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.eventsOn,
    required this.onSelectDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // weekday: 1 = lundi ... 7 = dimanche.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left),
                color: _kNavy,
                tooltip: 'Previous month',
              ),
              Expanded(
                child: Text(
                  '${_monthLabels[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kNavy,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right),
                color: _kNavy,
                tooltip: 'Next month',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day =
                  DateTime(month.year, month.month, dayNumber);
              final isSelected =
                  selectedDay != null && _sameDay(day, selectedDay!);
              final isToday = _sameDay(day, today);
              final count = eventsOn(day);

              return _DayCell(
                day: day,
                isSelected: isSelected,
                isToday: isToday,
                eventCount: count,
                onTap: () => onSelectDay(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final int eventCount;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.eventCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = _kNavy;
    if (isSelected) textColor = Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? _kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: _kGreen, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (eventCount > 0) ...[
              const SizedBox(height: 3),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : _kGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
