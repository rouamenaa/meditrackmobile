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
      version: 9,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createUserCache(db);
        await _createPhysicalActivities(db);
        await _createAppointmentsModule(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Crée toujours les tables si elles n'existent pas encore
        await _createUserCache(db);
        await _createPhysicalActivities(db);
        await _createAppointmentsModule(db);
        // v8 : ajout des colonnes patient sur les rendez-vous existants
        await _ensureAppointmentPatientColumns(db);
        // v9 : lien vers les comptes médecins enregistrés dans le backend
        await _ensureAppointmentRoleColumns(db);
      },
    );
  }

  /// Ajoute les colonnes `patient_id` / `patient_name` si elles manquent
  /// (migration depuis une base < v8).
  Future<void> _ensureAppointmentPatientColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(appointments)');
    final names = columns.map((c) => c['name'] as String).toSet();
    if (!names.contains('patient_id')) {
      await db.execute('ALTER TABLE appointments ADD COLUMN patient_id TEXT');
    }
    if (!names.contains('patient_name')) {
      await db.execute('ALTER TABLE appointments ADD COLUMN patient_name TEXT');
    }
  }

  Future<void> _ensureAppointmentRoleColumns(Database db) async {
    final practitionerColumns =
        await db.rawQuery('PRAGMA table_info(practitioners)');
    final practitionerNames =
        practitionerColumns.map((c) => c['name'] as String).toSet();
    if (!practitionerNames.contains('remote_user_id')) {
      await db.execute(
        'ALTER TABLE practitioners ADD COLUMN remote_user_id TEXT',
      );
    }

    final appointmentColumns =
        await db.rawQuery('PRAGMA table_info(appointments)');
    final appointmentNames =
        appointmentColumns.map((c) => c['name'] as String).toSet();
    if (!appointmentNames.contains('remote_id')) {
      await db.execute('ALTER TABLE appointments ADD COLUMN remote_id TEXT');
    }
    if (!appointmentNames.contains('doctor_user_id')) {
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN doctor_user_id TEXT',
      );
    }
    if (!appointmentNames.contains('facility_name')) {
      await db.execute('ALTER TABLE appointments ADD COLUMN facility_name TEXT');
    }
    if (!appointmentNames.contains('facility_address')) {
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN facility_address TEXT',
      );
    }
  }

  Future<void> _createUserCache(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_cache (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPhysicalActivities(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS physical_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        distance_km REAL,
        intensity TEXT NOT NULL,
        activity_date TEXT NOT NULL,
        notes TEXT,
        calories_burned INTEGER
      )
    ''');
  }

  Future<void> _createAppointmentsModule(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS practitioners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_name TEXT NOT NULL,
        first_name TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT 'Dr',
        specialty TEXT NOT NULL,
        rpps_adeli TEXT,
        phone TEXT,
        email TEXT,
        remote_user_id TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_facilities (
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
      CREATE TABLE IF NOT EXISTS appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        practitioner_id INTEGER NOT NULL,
        remote_id TEXT,
        doctor_user_id TEXT,
        facility_id INTEGER,
        facility_name TEXT,
        facility_address TEXT,
        patient_id TEXT,
        patient_name TEXT,
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
    final existingPractitioners = await db.query('practitioners', limit: 1);
    if (existingPractitioners.isEmpty) {
      await _seedInitialData(db);
    }
  }

  Future<void> _seedInitialData(Database db) async {
    // Praticiens de démonstration
    await db.insert('practitioners', {
      'last_name': 'Ben Salah',
      'first_name': 'Sami',
      'title': 'Dr',
      'specialty': 'General Medicine',
      'rpps_adeli': '10003456789',
      'phone': '+216 71 234 567',
      'email': 'sami.bensalah@meditrack.tn',
    });
    await db.insert('practitioners', {
      'last_name': 'Mansouri',
      'first_name': 'Leila',
      'title': 'Dr',
      'specialty': 'Cardiology',
      'rpps_adeli': '10008765432',
      'phone': '+216 71 890 123',
      'email': 'leila.mansouri@meditrack.tn',
    });
    await db.insert('practitioners', {
      'last_name': 'Trabelsi',
      'first_name': 'Mohamed',
      'title': 'Pr',
      'specialty': 'Pulmonology',
      'rpps_adeli': '10005432198',
      'phone': '+216 71 456 789',
      'email': 'm.trabelsi@meditrack.tn',
    });

    // Structures de santé de démonstration
    await db.insert('health_facilities', {
      'name': 'El Amen Medical Office',
      'type': 'Medical Office',
      'address': '12 Avenue Habib Bourguiba, Tunis',
      'building_floor': '2nd floor, Office B',
      'latitude': 36.8008,
      'longitude': 10.1800,
    });
    await db.insert('health_facilities', {
      'name': 'Les Jasmins Polyclinic',
      'type': 'Polyclinic',
      'address': 'Centre Urbain Nord, Tunis',
      'building_floor': 'Building B, Ground floor',
      'latitude': 36.8450,
      'longitude': 10.1980,
    });
    await db.insert('health_facilities', {
      'name': 'Main Military Hospital',
      'type': 'Hospital',
      'address': 'Montfleury, Tunis',
      'building_floor': 'South Wing, Outpatient Clinic',
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

  Future<Practitioner> upsertDoctorPractitioner(
    Practitioner practitioner,
  ) async {
    final db = await database;
    final remoteUserId = practitioner.remoteUserId;
    if (remoteUserId == null || remoteUserId.isEmpty) {
      throw ArgumentError('A remote user ID is required for a doctor account');
    }

    final existing = await db.query(
      'practitioners',
      where: 'remote_user_id = ?',
      whereArgs: [remoteUserId],
      limit: 1,
    );
    final values = practitioner.toMap()..remove('id');
    if (existing.isEmpty) {
      final id = await db.insert('practitioners', values);
      return practitioner.copyWith(id: id);
    }

    final id = existing.first['id'] as int;
    await db.update(
      'practitioners',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return practitioner.copyWith(id: id);
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
        a.patient_id AS a_patient_id,
        a.patient_name AS a_patient_name,
        a.remote_id AS a_remote_id,
        a.doctor_user_id AS a_doctor_user_id,
        a.facility_name AS a_facility_name,
        a.facility_address AS a_facility_address,
        
        p.id AS p_id,
        p.last_name AS p_last_name,
        p.first_name AS p_first_name,
        p.title AS p_title,
        p.specialty AS p_specialty,
        p.rpps_adeli AS p_rpps_adeli,
        p.phone AS p_phone,
        p.email AS p_email,
        p.remote_user_id AS p_remote_user_id,
        
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
        remoteUserId: r['p_remote_user_id'] as String?,
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
        remoteId: r['a_remote_id'] as String?,
        practitionerId: r['a_practitioner_id'] as int,
        doctorUserId: r['a_doctor_user_id'] as String?,
        facilityId: r['a_facility_id'] as int?,
        facilityName: r['a_facility_name'] as String?,
        facilityAddress: r['a_facility_address'] as String?,
        patientId: r['a_patient_id'] as String?,
        patientName: r['a_patient_name'] as String?,
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
        a.patient_id AS a_patient_id,
        a.patient_name AS a_patient_name,
        a.remote_id AS a_remote_id,
        a.doctor_user_id AS a_doctor_user_id,
        a.facility_name AS a_facility_name,
        a.facility_address AS a_facility_address,
        
        p.id AS p_id,
        p.last_name AS p_last_name,
        p.first_name AS p_first_name,
        p.title AS p_title,
        p.specialty AS p_specialty,
        p.rpps_adeli AS p_rpps_adeli,
        p.phone AS p_phone,
        p.email AS p_email,
        p.remote_user_id AS p_remote_user_id,
        
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
      remoteUserId: r['p_remote_user_id'] as String?,
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
      remoteId: r['a_remote_id'] as String?,
      practitionerId: r['a_practitioner_id'] as int,
      doctorUserId: r['a_doctor_user_id'] as String?,
      facilityId: r['a_facility_id'] as int?,
      facilityName: r['a_facility_name'] as String?,
      facilityAddress: r['a_facility_address'] as String?,
      patientId: r['a_patient_id'] as String?,
      patientName: r['a_patient_name'] as String?,
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
