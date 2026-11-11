/// Helpers date/heure en français — sans package intl
/// (on formate à la main, comme vu en cours : padLeft + interpolation).
library;

const _mois = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _jours = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// "05/09/2026"
String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// "20:00" ou "20:07"
String fmtTime(DateTime d) =>
    '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

/// "Mercredi 12 août"
String fmtDateLettres(DateTime d) =>
    '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';

/// "Aujourd'hui à 20:00" / "Demain à 08:00" / "Lundi 3 sept. à 08:00"
String fmtProchainePrise(DateTime? next, DateTime now) {
  if (next == null) return '—';
  final jour = DateTime(next.year, next.month, next.day);
  final auj = DateTime(now.year, now.month, now.day);
  if (jour == auj) return "Today at ${fmtTime(next)}";
  if (jour == auj.add(const Duration(days: 1))) {
    return 'Tomorrow at ${fmtTime(next)}';
  }
  return '${fmtDateLettres(next)} at ${fmtTime(next)}';
}

/// "01/09/2026 – 30/09/2026" ou "Depuis 01/09/2026 · chronique"
String fmtPeriode(DateTime start, DateTime? end) => end == null
    ? 'Since ${fmtDate(start)} · chronic'
    : '${fmtDate(start)} – ${fmtDate(end)}';
