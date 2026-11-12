class Practitioner {
  final int? id;
  final String lastName;
  final String firstName;
  final String title; // "Dr", "Pr", etc.
  final String specialty;
  final String? rppsAdeli;
  final String? phone;
  final String? email;
  final String? remoteUserId;

  Practitioner({
    this.id,
    required this.lastName,
    required this.firstName,
    this.title = 'Dr',
    required this.specialty,
    this.rppsAdeli,
    this.phone,
    this.email,
    this.remoteUserId,
  });

  String get fullName => '$title $firstName $lastName'.trim();

  Map<String, dynamic> toMap() => {
    'id': id,
    'last_name': lastName,
    'first_name': firstName,
    'title': title,
    'specialty': specialty,
    'rpps_adeli': rppsAdeli,
    'phone': phone,
    'email': email,
    'remote_user_id': remoteUserId,
  };

  factory Practitioner.fromMap(Map<String, dynamic> map) => Practitioner(
    id: map['id'] as int?,
    lastName: (map['last_name'] ?? '') as String,
    firstName: (map['first_name'] ?? '') as String,
    title: (map['title'] ?? 'Dr') as String,
    specialty: (map['specialty'] ?? '') as String,
    rppsAdeli: map['rpps_adeli'] as String?,
    phone: map['phone'] as String?,
    email: map['email'] as String?,
    remoteUserId: map['remote_user_id'] as String?,
  );

  Practitioner copyWith({
    int? id,
    String? lastName,
    String? firstName,
    String? title,
    String? specialty,
    String? rppsAdeli,
    String? phone,
    String? email,
    String? remoteUserId,
  }) {
    return Practitioner(
      id: id ?? this.id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      rppsAdeli: rppsAdeli ?? this.rppsAdeli,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      remoteUserId: remoteUserId ?? this.remoteUserId,
    );
  }
}
