import 'package:meditrackmobile/config.dart';

import 'medecin.dart';

class User {
  final String? id; // ObjectId MongoDB (texte)
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? dateNaissance; // "1987-04-14"
  final String? sexe;

  // Préférences de notification
  final bool notifMedicaments;
  final bool notifRdv;
  final bool notifSon;
  final bool notifVibration;
  final int rappelAvantMinutes;

  // Profil santé
  final String? photo; // chemin relatif : "uploads/xxx.jpg"
  final String? groupeSanguin;
  final String? conditionMedicale;
  final String? contactUrgenceNom;
  final String? contactUrgenceLien;
  final String? contactUrgenceTel;
  final String? assuranceNom;
  final String? assurancePolice;
  final String? createdAt;
  final List<Medecin> medecins;

  User({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.dateNaissance,
    this.sexe,
    this.notifMedicaments = true,
    this.notifRdv = true,
    this.notifSon = true,
    this.notifVibration = true,
    this.rappelAvantMinutes = 10,
    this.photo,
    this.groupeSanguin,
    this.conditionMedicale,
    this.contactUrgenceNom,
    this.contactUrgenceLien,
    this.contactUrgenceTel,
    this.assuranceNom,
    this.assurancePolice,
    this.createdAt,
    this.medecins = const [],
  });

  // ---------- Valeurs calculées (utiles pour tous les modules) ----------
  String get fullName => '$prenom $nom';

  String get meditrackId {
    final s = id ?? '0000';
    return '#MT-${s.substring(s.length - 4).toUpperCase()}';
  }

  String? get photoUrl => (photo == null || photo!.isEmpty) ? null : '$kBaseUrl/$photo';

  int? get age {
    final d = DateTime.tryParse(dateNaissance ?? '');
    if (d == null) return null;
    final now = DateTime.now();
    var a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return a;
  }

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String?,
    nom: j['nom'] as String? ?? '',
    prenom: j['prenom'] as String? ?? '',
    email: j['email'] as String? ?? '',
    telephone: j['telephone'] as String?,
    dateNaissance: j['date_naissance'] as String?,
    sexe: j['sexe'] as String?,
    notifMedicaments: j['notif_medicaments'] as bool? ?? true,
    notifRdv: j['notif_rdv'] as bool? ?? true,
    notifSon: j['notif_son'] as bool? ?? true,
    notifVibration: j['notif_vibration'] as bool? ?? true,
    rappelAvantMinutes: (j['rappel_avant_minutes'] as num?)?.toInt() ?? 10,
    photo: j['photo'] as String?,
    groupeSanguin: j['groupe_sanguin'] as String?,
    conditionMedicale: j['condition_medicale'] as String?,
    contactUrgenceNom: j['contact_urgence_nom'] as String?,
    contactUrgenceLien: j['contact_urgence_lien'] as String?,
    contactUrgenceTel: j['contact_urgence_tel'] as String?,
    assuranceNom: j['assurance_nom'] as String?,
    assurancePolice: j['assurance_police'] as String?,
    createdAt: j['createdAt'] as String?,
    medecins: ((j['medecins'] as List?) ?? [])
        .map((m) => Medecin.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );

  // Sert à la copie locale (SQLite)
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'telephone': telephone,
    'date_naissance': dateNaissance,
    'sexe': sexe,
    'notif_medicaments': notifMedicaments,
    'notif_rdv': notifRdv,
    'notif_son': notifSon,
    'notif_vibration': notifVibration,
    'rappel_avant_minutes': rappelAvantMinutes,
    'photo': photo,
    'groupe_sanguin': groupeSanguin,
    'condition_medicale': conditionMedicale,
    'contact_urgence_nom': contactUrgenceNom,
    'contact_urgence_lien': contactUrgenceLien,
    'contact_urgence_tel': contactUrgenceTel,
    'assurance_nom': assuranceNom,
    'assurance_police': assurancePolice,
    'createdAt': createdAt,
    'medecins': medecins.map((m) => m.toJson()).toList(),
  };
}