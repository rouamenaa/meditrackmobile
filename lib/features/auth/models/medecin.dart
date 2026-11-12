class Medecin {
  final String? id;
  final String nom;
  final String specialite;

  Medecin({this.id, required this.nom, required this.specialite});

  factory Medecin.fromJson(Map<String, dynamic> j) => Medecin(
        id: j['id'] as String?,
        nom: j['nom'] as String? ?? '',
        specialite: j['specialite'] as String? ?? '',
      );

  factory Medecin.fromMap(Map<String, dynamic> j) => Medecin.fromJson(j);

  Map<String, dynamic> toJson() =>
      {'id': id, 'nom': nom, 'specialite': specialite};

  Map<String, dynamic> toMap() => toJson();
}