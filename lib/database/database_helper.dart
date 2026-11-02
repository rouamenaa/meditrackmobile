import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../features/appointments/models/appointment.dart';
import '../features/appointments/models/appointment_status.dart';
import '../features/appointments/models/health_facility.dart';
import '../features/appointments/models/practitioner.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'meditrack.db');
    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createV1(db);
        await _migrateToV2(db);
        await _migrateToV3(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateToV2(db);
        if (oldVersion < 3) await _migrateToV3(db);
      },
    );
  }

  Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        telephone TEXT,
        date_naissance TEXT,
        sexe TEXT,
        notif_medicaments INTEGER NOT NULL DEFAULT 1,
        notif_rdv INTEGER NOT NULL DEFAULT 1,
        notif_son INTEGER NOT NULL DEFAULT 1,
        notif_vibration INTEGER NOT NULL DEFAULT 1,
        rappel_avant_minutes INTEGER NOT NULL DEFAULT 10
      )
    ''');
  }

  Future<void> _migrateToV2(Database db) async {
    const newColumns = [
      'date_creation',
      'photo_path',
      'groupe_sanguin',
      'condition_medicale',
      'contact_urgence_nom',
      'contact_urgence_lien',
      'contact_urgence_tel',
      'assurance_nom',
      'assurance_police',
    ];
    for (final col in newColumns) {
      await db.execute('ALTER TABLE users ADD COLUMN $col TEXT');
    }

    await db.execute('''
      CREATE TABLE medecins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nom TEXT NOT NULL,
        specialite TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migrateToV3(Database db) async {
    await db.execute('''
      CREATE TABLE practitioners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_name TEXT NOT NULL,
        first_name TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT 'Dr',
        specialty TEXT NOT NULL,
        rpps_adeli TEXT,
        phone TEXT,
        email TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE health_facilities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        address TEXT NOT NULL,
        building_floor TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        practitioner_id INTEGER NOT NULL,
        facility_id INTEGER,
        start_date_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 30,
        reason TEXT NOT NULL,
        notes TEXT,
        modality TEXT NOT NULL DEFAULT 'presentiel',
        video_url TEXT,
        status TEXT NOT NULL DEFAULT 'SCHEDULED',
        FOREIGN KEY (practitioner_id) REFERENCES practitioners(id) ON DELETE CASCADE,
        FOREIGN KEY (facility_id) REFERENCES health_facilities(id) ON DELETE SET NULL
      )
    ''');

    // Insertion initiale de praticiens et structures par défaut si la base est vide
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Praticiens de démonstration
    await db.insert('practitioners', {
      'last_name': 'Ben Salah',
      'first_name': 'Sami',
      'title': 'Dr',
      'specialty': 'Médecine Générale',
      'rpps_adeli': '10003456789',
      'phone': '+216 71 234 567',
      'email': 'sami.bensalah@meditrack.tn',
    });
    await db.insert('practitioners', {
      'last_name': 'Mansouri',
      'first_name': 'Leila',
      'title': 'Dr',
      'specialty': 'Cardiologie',
      'rpps_adeli': '10008765432',
      'phone': '+216 71 890 123',
      'email': 'leila.mansouri@meditrack.tn',
    });
    await db.insert('practitioners', {
      'last_name': 'Trabelsi',
      'first_name': 'Mohamed',
      'title': 'Pr',
      'specialty': 'Pneumologie',
      'rpps_adeli': '10005432198',
      'phone': '+216 71 456 789',
      'email': 'm.trabelsi@meditrack.tn',
    });

    // Structures de santé de démonstration
    await db.insert('health_facilities', {
      'name': 'Cabinet Médical El Amen',
      'type': 'cabinet',
      'address': '12 Avenue Habib Bourguiba, Tunis',
      'building_floor': '2ème étage, Cabinet B',
      'latitude': 36.8008,
      'longitude': 10.1800,
    });
    await db.insert('health_facilities', {
      'name': 'Polyclinique Les Jasmins',
      'type': 'polyclinique',
      'address': 'Centre Urbain Nord, Tunis',
      'building_floor': 'Bâtiment B, RDC',
      'latitude': 36.8450,
      'longitude': 10.1980,
    });
    await db.insert('health_facilities', {
      'name': 'Hôpital Militaire Principal',
      'type': 'hôpital',
      'address': 'Montfleury, Tunis',
      'building_floor': 'Aile Sud, Consultation Externe',
      'latitude': 36.7860,
      'longitude': 10.1650,
    });
  }

  // ===========================================================================
  // CRUD : PRACTITIONERS
  // ===========================================================================

  Future<int> insertPractitioner(Practitioner practitioner) async {
    final db = await database;
    return await db.insert('practitioners', practitioner.toMap()..remove('id'));
  }

  Future<List<Practitioner>> getAllPractitioners() async {
    final db = await database;
    final rows = await db.query(
      'practitioners',
      orderBy: 'last_name ASC, first_name ASC',
    );
    return rows.map((r) => Practitioner.fromMap(r)).toList();
  }

  Future<Practitioner?> getPractitionerById(int id) async {
    final db = await database;
    final rows = await db.query(
      'practitioners',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Practitioner.fromMap(rows.first);
  }

  Future<int> updatePractitioner(Practitioner practitioner) async {
    final db = await database;
    return await db.update(
      'practitioners',
      practitioner.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [practitioner.id],
    );
  }

  Future<int> deletePractitioner(int id) async {
    final db = await database;
    return await db.delete(
      'practitioners',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // CRUD : HEALTH FACILITIES
  // ===========================================================================

  Future<int> insertHealthFacility(HealthFacility facility) async {
    final db = await database;
    return await db.insert('health_facilities', facility.toMap()..remove('id'));
  }

  Future<List<HealthFacility>> getAllHealthFacilities() async {
    final db = await database;
    final rows = await db.query(
      'health_facilities',
      orderBy: 'name ASC',
    );
    return rows.map((r) => HealthFacility.fromMap(r)).toList();
  }

  Future<HealthFacility?> getHealthFacilityById(int id) async {
    final db = await database;
    final rows = await db.query(
      'health_facilities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HealthFacility.fromMap(rows.first);
  }

  Future<int> updateHealthFacility(HealthFacility facility) async {
    final db = await database;
    return await db.update(
      'health_facilities',
      facility.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [facility.id],
    );
  }

  Future<int> deleteHealthFacility(int id) async {
    final db = await database;
    return await db.delete(
      'health_facilities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // CRUD : APPOINTMENTS (avec jointures pour praticien & structure)
  // ===========================================================================

  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment.toMap()..remove('id'));
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 
        a.id AS a_id,
        a.practitioner_id AS a_practitioner_id,
        a.facility_id AS a_facility_id,
        a.start_date_time AS a_start_date_time,
        a.duration_minutes AS a_duration_minutes,
        a.reason AS a_reason,
        a.notes AS a_notes,
        a.modality AS a_modality,
        a.video_url AS a_video_url,
        a.status AS a_status,
        
        p.id AS p_id,
        p.last_name AS p_last_name,
        p.first_name AS p_first_name,
        p.title AS p_title,
        p.specialty AS p_specialty,
        p.rpps_adeli AS p_rpps_adeli,
        p.phone AS p_phone,
        p.email AS p_email,
        
        f.id AS f_id,
        f.name AS f_name,
        f.type AS f_type,
        f.address AS f_address,
        f.building_floor AS f_building_floor,
        f.latitude AS f_latitude,
        f.longitude AS f_longitude
      FROM appointments a
      INNER JOIN practitioners p ON a.practitioner_id = p.id
      LEFT JOIN health_facilities f ON a.facility_id = f.id
      ORDER BY a.start_date_time ASC
    ''');

    return rows.map((r) {
      final practitioner = Practitioner(
        id: r['p_id'] as int?,
        lastName: (r['p_last_name'] ?? '') as String,
        firstName: (r['p_first_name'] ?? '') as String,
        title: (r['p_title'] ?? 'Dr') as String,
        specialty: (r['p_specialty'] ?? '') as String,
        rppsAdeli: r['p_rpps_adeli'] as String?,
        phone: r['p_phone'] as String?,
        email: r['p_email'] as String?,
      );

      HealthFacility? facility;
      if (r['f_id'] != null) {
        facility = HealthFacility(
          id: r['f_id'] as int?,
          name: (r['f_name'] ?? '') as String,
          type: (r['f_type'] ?? '') as String,
          address: (r['f_address'] ?? '') as String,
          buildingFloor: r['f_building_floor'] as String?,
          latitude: (r['f_latitude'] as num?)?.toDouble(),
          longitude: (r['f_longitude'] as num?)?.toDouble(),
        );
      }

      return Appointment(
        id: r['a_id'] as int?,
        practitionerId: r['a_practitioner_id'] as int,
        facilityId: r['a_facility_id'] as int?,
        startDateTime: DateTime.parse(r['a_start_date_time'] as String),
        durationMinutes: (r['a_duration_minutes'] as int?) ?? 30,
        reason: (r['a_reason'] ?? '') as String,
        notes: r['a_notes'] as String?,
        modality: (r['a_modality'] ?? 'presentiel') as String,
        videoUrl: r['a_video_url'] as String?,
        status: AppointmentStatus.fromString(r['a_status'] as String?),
        practitioner: practitioner,
        facility: facility,
      );
    }).toList();
  }

  Future<Appointment?> getAppointmentById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 
        a.id AS a_id,
        a.practitioner_id AS a_practitioner_id,
        a.facility_id AS a_facility_id,
        a.start_date_time AS a_start_date_time,
        a.duration_minutes AS a_duration_minutes,
        a.reason AS a_reason,
        a.notes AS a_notes,
        a.modality AS a_modality,
        a.video_url AS a_video_url,
        a.status AS a_status,
        
        p.id AS p_id,
        p.last_name AS p_last_name,
        p.first_name AS p_first_name,
        p.title AS p_title,
        p.specialty AS p_specialty,
        p.rpps_adeli AS p_rpps_adeli,
        p.phone AS p_phone,
        p.email AS p_email,
        
        f.id AS f_id,
        f.name AS f_name,
        f.type AS f_type,
        f.address AS f_address,
        f.building_floor AS f_building_floor,
        f.latitude AS f_latitude,
        f.longitude AS f_longitude
      FROM appointments a
      INNER JOIN practitioners p ON a.practitioner_id = p.id
      LEFT JOIN health_facilities f ON a.facility_id = f.id
      WHERE a.id = ?
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;
    final r = rows.first;

    final practitioner = Practitioner(
      id: r['p_id'] as int?,
      lastName: (r['p_last_name'] ?? '') as String,
      firstName: (r['p_first_name'] ?? '') as String,
      title: (r['p_title'] ?? 'Dr') as String,
      specialty: (r['p_specialty'] ?? '') as String,
      rppsAdeli: r['p_rpps_adeli'] as String?,
      phone: r['p_phone'] as String?,
      email: r['p_email'] as String?,
    );

    HealthFacility? facility;
    if (r['f_id'] != null) {
      facility = HealthFacility(
        id: r['f_id'] as int?,
        name: (r['f_name'] ?? '') as String,
        type: (r['f_type'] ?? '') as String,
        address: (r['f_address'] ?? '') as String,
        buildingFloor: r['f_building_floor'] as String?,
        latitude: (r['f_latitude'] as num?)?.toDouble(),
        longitude: (r['f_longitude'] as num?)?.toDouble(),
      );
    }

    return Appointment(
      id: r['a_id'] as int?,
      practitionerId: r['a_practitioner_id'] as int,
      facilityId: r['a_facility_id'] as int?,
      startDateTime: DateTime.parse(r['a_start_date_time'] as String),
      durationMinutes: (r['a_duration_minutes'] as int?) ?? 30,
      reason: (r['a_reason'] ?? '') as String,
      notes: r['a_notes'] as String?,
      modality: (r['a_modality'] ?? 'presentiel') as String,
      videoUrl: r['a_video_url'] as String?,
      status: AppointmentStatus.fromString(r['a_status'] as String?),
      practitioner: practitioner,
      facility: facility,
    );
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> updateAppointmentStatus(int id, AppointmentStatus status) async {
    final db = await database;
    return await db.update(
      'appointments',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}