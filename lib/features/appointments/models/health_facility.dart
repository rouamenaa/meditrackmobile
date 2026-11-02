class HealthFacility {
  final int? id;
  final String name;
  final String type; // cabinet, maison de santé, hôpital, polyclinique
  final String address;
  final String? buildingFloor;
  final double? latitude;
  final double? longitude;

  HealthFacility({
    this.id,
    required this.name,
    required this.type,
    required this.address,
    this.buildingFloor,
    this.latitude,
    this.longitude,
  });

  String get fullAddress =>
      buildingFloor != null && buildingFloor!.isNotEmpty
          ? '$address ($buildingFloor)'
          : address;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'address': address,
    'building_floor': buildingFloor,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory HealthFacility.fromMap(Map<String, dynamic> map) => HealthFacility(
    id: map['id'] as int?,
    name: (map['name'] ?? '') as String,
    type: (map['type'] ?? '') as String,
    address: (map['address'] ?? '') as String,
    buildingFloor: map['building_floor'] as String?,
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
  );

  HealthFacility copyWith({
    int? id,
    String? name,
    String? type,
    String? address,
    String? buildingFloor,
    double? latitude,
    double? longitude,
  }) {
    return HealthFacility(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      buildingFloor: buildingFloor ?? this.buildingFloor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
