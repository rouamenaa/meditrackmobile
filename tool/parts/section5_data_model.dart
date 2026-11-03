const String section5DataModelHtml = r'''
<div class="landscape">
  <h1><span class="chapter-num">5</span> Modélisation des Données Relationnelles (3NF)</h1>
  <p>Cette section formalise le schéma relationnel normalisé en 3e forme normale (3NF) pour la base locale chiffrée SQLite (SQLCipher). Ce modèle garantit l'intégrité référentielle, supprime la redondance et applique une politique rigoureuse de traçabilité médico-légale.</p>

  <div class="diagram-container">
    <div class="diagram-header">
      <span class="diagram-title">Figure 5.1 — Modèle Physique des Données Relationnelles (ERD)</span>
      <span class="diagram-type">Entity-Relationship Diagram</span>
    </div>
    <div class="mermaid">
erDiagram
    users ||--|| patient_profiles : "has profile"
    users ||--|| user_preferences : "has prefs"
    users ||--o{ security_logs : "audits"
    users ||--o{ physical_activities : "logs"
    users ||--o{ activity_goals : "targets"
    users ||--o{ medications : "owns"
    medications ||--o{ stock_movements : "tracks"
    users ||--o{ treatments : "follows"
    treatments ||--|{ prescription_items : "contains"
    prescription_items }o--|| medications : "refers to"
    prescription_items ||--|{ intake_schedules : "schedules"
    intake_schedules ||--o{ planned_intakes : "generates"
    planned_intakes ||--o| intake_logs : "records"
    users ||--o{ practitioners : "consults"
    practitioners }o--o| health_facilities : "practices in"
    users ||--o{ appointments : "books"
    appointments }o--|| practitioners : "involves"
    appointments }o--o| health_facilities : "locates at"
    appointments ||--o| consultation_records : "produces"

    users {
        TEXT id PK
        TEXT email UK
        TEXT password_hash
        TEXT salt
        TEXT pin_hash
        INTEGER is_biometric_enabled
        INTEGER failed_attempts
        TEXT lock_until
        TEXT created_at
        TEXT last_login_at
    }

    patient_profiles {
        TEXT id PK
        TEXT user_id FK
        TEXT first_name
        TEXT last_name
        TEXT birth_date
        TEXT sex
        REAL height_cm
        REAL weight_kg
        TEXT blood_group
        TEXT allergies_json
        TEXT medical_history_json
        TEXT emergency_contact_name
        TEXT emergency_contact_phone
    }

    medications {
        TEXT id PK
        TEXT user_id FK
        TEXT commercial_name
        TEXT generic_name_dci
        TEXT regulatory_code_cis
        REAL dosage_value
        TEXT dosage_unit
        TEXT form
        TEXT route
        REAL current_stock
        REAL min_stock_threshold
        TEXT expiry_date
        TEXT batch_number
        INTEGER is_deleted
    }

    treatments {
        TEXT id PK
        TEXT user_id FK
        TEXT title
        TEXT pathology
        TEXT prescribing_doctor
        TEXT start_date
        TEXT end_date
        INTEGER is_chronic
        TEXT status
        INTEGER is_deleted
    }

    planned_intakes {
        TEXT id PK
        TEXT intake_schedule_id FK
        TEXT scheduled_datetime
        REAL dose_to_take
        INTEGER tolerance_minutes
        TEXT status
    }

    appointments {
        TEXT id PK
        TEXT user_id FK
        TEXT practitioner_id FK
        TEXT health_facility_id FK
        TEXT start_datetime
        INTEGER duration_minutes
        TEXT purpose
        TEXT modality
        TEXT status
        INTEGER is_deleted
    }
    </div>
    <div class="diagram-caption">Figure 5.1 — Modèle Entité-Association (ERD) des tables relationnelles normalisées de MediTrack.</div>
  </div>
</div>

<div class="page-break"></div>

<h2>5.2 Dictionnaire Détaillé des 14 Tables de la Base de Données</h2>
<p>Chaque table est auditée ci-après avec la totalité de ses contraintes physiques d'intégrité :</p>

<h3>1. Table <code>users</code> (Comptes & Sécurité)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY (UUID v4)</td><td>Identifiant unique universel du compte utilisateur.</td></tr>
    <tr><td><code>email</code></td><td>TEXT</td><td>NOT NULL UNIQUE</td><td>Adresse de courrier électronique (normalisée en minuscules).</td></tr>
    <tr><td><code>password_hash</code></td><td>TEXT</td><td>NOT NULL</td><td>Hachage PBKDF2/Argon2id du mot de passe maître.</td></tr>
    <tr><td><code>salt</code></td><td>TEXT</td><td>NOT NULL</td><td>Sel cryptographique de 128 bits spécifique à l'utilisateur.</td></tr>
    <tr><td><code>pin_hash</code></td><td>TEXT</td><td>NULL</td><td>Hachage sécurisé du code PIN à 6 chiffres de secours.</td></tr>
    <tr><td><code>is_biometric_enabled</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 0 CHECK (is_biometric_enabled IN (0, 1))</td><td>Indicateur d'activation du déverrouillage biométrique.</td></tr>
    <tr><td><code>failed_attempts</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 0</td><td>Compteur d'échecs consécutifs d'authentification.</td></tr>
    <tr><td><code>lock_until</code></td><td>TEXT</td><td>NULL</td><td>Horodatage UTC de déblocage en cas d'attaque par force brute.</td></tr>
    <tr><td><code>created_at</code></td><td>TEXT</td><td>NOT NULL DEFAULT (datetime('now'))</td><td>Date/heure de création du compte (UTC ISO-8601).</td></tr>
    <tr><td><code>last_login_at</code></td><td>TEXT</td><td>NULL</td><td>Dernière connexion réussie enregistrée.</td></tr>
  </tbody>
</table>

<h3>2. Table <code>patient_profiles</code> (Données Cliniques & Contacts d'Urgence)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant unique du profil médical.</td></tr>
    <tr><td><code>user_id</code></td><td>TEXT</td><td>NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE</td><td>Clé étrangère 1-1 vers le compte utilisateur.</td></tr>
    <tr><td><code>first_name</code></td><td>TEXT</td><td>NOT NULL</td><td>Prénom usuel du patient.</td></tr>
    <tr><td><code>last_name</code></td><td>TEXT</td><td>NOT NULL</td><td>Nom de famille du patient.</td></tr>
    <tr><td><code>birth_date</code></td><td>TEXT</td><td>NOT NULL</td><td>Date de naissance (format AAAA-MM-JJ).</td></tr>
    <tr><td><code>sex</code></td><td>TEXT</td><td>NOT NULL CHECK (sex IN ('MALE', 'FEMALE', 'OTHER'))</td><td>Sexe biologique pour les calculs physiologiques.</td></tr>
    <tr><td><code>height_cm</code></td><td>REAL</td><td>NOT NULL CHECK (height_cm BETWEEN 40.0 AND 250.0)</td><td>Taille en centimètres.</td></tr>
    <tr><td><code>weight_kg</code></td><td>REAL</td><td>NOT NULL CHECK (weight_kg BETWEEN 2.0 AND 350.0)</td><td>Poids corporel actuel en kilogrammes.</td></tr>
    <tr><td><code>blood_group</code></td><td>TEXT</td><td>NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))</td><td>Groupe sanguin avec facteur Rhésus.</td></tr>
    <tr><td><code>allergies_json</code></td><td>TEXT</td><td>NOT NULL DEFAULT '[]'</td><td>Tableau JSON sérialisé des allergies déclarées.</td></tr>
    <tr><td><code>medical_history_json</code></td><td>TEXT</td><td>NOT NULL DEFAULT '[]'</td><td>Tableau JSON sérialisé des antécédents médicaux.</td></tr>
    <tr><td><code>emergency_contact_name</code></td><td>TEXT</td><td>NULL</td><td>Nom de la personne de confiance / contact d'urgence.</td></tr>
    <tr><td><code>emergency_contact_phone</code></td><td>TEXT</td><td>NULL</td><td>Numéro téléphonique direct du contact d'urgence.</td></tr>
  </tbody>
</table>

<h3>3. Table <code>user_preferences</code> (Matrice de Confidentialité & Notifications)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant unique de la configuration.</td></tr>
    <tr><td><code>user_id</code></td><td>TEXT</td><td>NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE</td><td>Clé étrangère 1-1 vers l'utilisateur.</td></tr>
    <tr><td><code>is_discrete_mode</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 0</td><td>Masque le libellé de molécule sur l'écran verrouillé.</td></tr>
    <tr><td><code>enable_sound</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 1</td><td>Active les notifications sonores locales.</td></tr>
    <tr><td><code>enable_vibration</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 1</td><td>Active le moteur de retour haptique / vibreur.</td></tr>
    <tr><td><code>quiet_hours_start</code></td><td>TEXT</td><td>NULL</td><td>Heure de début du mode silencieux (HH:mm).</td></tr>
    <tr><td><code>quiet_hours_end</code></td><td>TEXT</td><td>NULL</td><td>Heure de fin du mode silencieux (HH:mm).</td></tr>
    <tr><td><code>allow_critical_in_quiet</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 1</td><td>Maintient les sonneries des prises classées vitales.</td></tr>
  </tbody>
</table>

<h3>4. Table <code>physical_activities</code> (Journal des Séances Sportives)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant unique de la séance.</td></tr>
    <tr><td><code>user_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES users(id) ON DELETE CASCADE</td><td>Clé étrangère vers le patient.</td></tr>
    <tr><td><code>activity_type</code></td><td>TEXT</td><td>NOT NULL</td><td>Type de discipline (WALKING, RUNNING, CYCLING...).</td></tr>
    <tr><td><code>start_datetime</code></td><td>TEXT</td><td>NOT NULL</td><td>Date et heure de début de la séance (ISO-8601 UTC).</td></tr>
    <tr><td><code>duration_minutes</code></td><td>INTEGER</td><td>NOT NULL CHECK (duration_minutes &gt; 0)</td><td>Durée d'effort en minutes.</td></tr>
    <tr><td><code>distance_km</code></td><td>REAL</td><td>NULL CHECK (distance_km &gt;= 0.0)</td><td>Distance parcourue (km, optionnelle selon activité).</td></tr>
    <tr><td><code>intensity</code></td><td>TEXT</td><td>NOT NULL CHECK (intensity IN ('LIGHT', 'MODERATE', 'VIGOROUS'))</td><td>Niveau d'intensité métabolique perçue.</td></tr>
    <tr><td><code>rpe_score</code></td><td>INTEGER</td><td>NULL CHECK (rpe_score BETWEEN 1 AND 10)</td><td>Score d'effort RPE sur l'échelle de Borg.</td></tr>
    <tr><td><code>calories_burned</code></td><td>REAL</td><td>NOT NULL CHECK (calories_burned &gt;= 0.0)</td><td>Dépense énergétique calculée ou déclarée (kcal).</td></tr>
    <tr><td><code>avg_heart_rate_bpm</code></td><td>INTEGER</td><td>NULL</td><td>Fréquence cardiaque moyenne (si capteur).</td></tr>
    <tr><td><code>notes</code></td><td>TEXT</td><td>NULL</td><td>Ressenti subjectif ou remarques sur la séance.</td></tr>
    <tr><td><code>data_source</code></td><td>TEXT</td><td>NOT NULL CHECK (data_source IN ('MANUAL_DECLARATIVE', 'CALCULATED_INTERNAL', 'EXTERNAL_SENSOR_SYNC'))</td><td>Origine technique de la donnée enregistrée.</td></tr>
  </tbody>
</table>

<h3>5. Table <code>activity_goals</code> (Objectifs d'Activité et Cibles OMS)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant de l'objectif.</td></tr>
    <tr><td><code>user_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES users(id) ON DELETE CASCADE</td><td>Clé étrangère vers le patient.</td></tr>
    <tr><td><code>frequency</code></td><td>TEXT</td><td>NOT NULL CHECK (frequency IN ('DAILY', 'WEEKLY'))</td><td>Périodicité de l'objectif.</td></tr>
    <tr><td><code>target_duration_minutes</code></td><td>INTEGER</td><td>NOT NULL CHECK (target_duration_minutes &gt; 0)</td><td>Durée active cible (ex: 150 min/semaine).</td></tr>
    <tr><td><code>target_calories</code></td><td>REAL</td><td>NULL</td><td>Objectif calorique optionnel.</td></tr>
    <tr><td><code>target_steps</code></td><td>INTEGER</td><td>NULL</td><td>Objectif de pas quotidiens (ex: 10 000).</td></tr>
    <tr><td><code>is_active</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 1</td><td>Indicateur d'activation de la cible.</td></tr>
  </tbody>
</table>

<h3>6. Table <code>medications</code> (Inventaire de l'Armoire à Pharmacie)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant unique de la boîte/médicament.</td></tr>
    <tr><td><code>user_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES users(id) ON DELETE CASCADE</td><td>Propriétaire du stock personnel.</td></tr>
    <tr><td><code>commercial_name</code></td><td>TEXT</td><td>NOT NULL</td><td>Nom de marque ou de spécialité (ex: Doliprane).</td></tr>
    <tr><td><code>generic_name_dci</code></td><td>TEXT</td><td>NOT NULL</td><td>Dénomination Commune Internationale (ex: Paracétamol).</td></tr>
    <tr><td><code>regulatory_code_cis</code></td><td>TEXT</td><td>NULL</td><td>Code d'Identification de Spécialité réglementaire.</td></tr>
    <tr><td><code>dosage_value</code></td><td>REAL</td><td>NOT NULL CHECK (dosage_value &gt; 0)</td><td>Quantité de principe actif par unité (ex: 500).</td></tr>
    <tr><td><code>dosage_unit</code></td><td>TEXT</td><td>NOT NULL</td><td>Unité de mesure (mg, g, ml, UI, µg, bouffée).</td></tr>
    <tr><td><code>form</code></td><td>TEXT</td><td>NOT NULL</td><td>Forme pharmaceutique (TABLET, CAPSULE, SYRUP...).</td></tr>
    <tr><td><code>route</code></td><td>TEXT</td><td>NOT NULL</td><td>Voie d'administration (ORAL, SUBLINGUAL, CUTANEOUS...).</td></tr>
    <tr><td><code>current_stock</code></td><td>REAL</td><td>NOT NULL DEFAULT 0 CHECK (current_stock &gt;= 0)</td><td>Unités de prises physiques actuellement disponibles.</td></tr>
    <tr><td><code>min_stock_threshold</code></td><td>REAL</td><td>NOT NULL DEFAULT 5 CHECK (min_stock_threshold &gt;= 0)</td><td>Seuil déclenchant l'alerte de réapprovisionnement.</td></tr>
    <tr><td><code>expiry_date</code></td><td>TEXT</td><td>NOT NULL</td><td>Date de péremption du lot (AAAA-MM-JJ).</td></tr>
    <tr><td><code>batch_number</code></td><td>TEXT</td><td>NULL</td><td>Numéro de lot de fabrication pharmaceutique.</td></tr>
    <tr><td><code>is_deleted</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 0</td><td>Indicateur de Soft Delete (traçabilité légale).</td></tr>
  </tbody>
</table>

<h3>7. Table <code>stock_movements</code> (Traçabilité & Audit des Flux d'Inventaire)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant du mouvement d'inventaire.</td></tr>
    <tr><td><code>medication_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES medications(id) ON DELETE CASCADE</td><td>Médicament concerné.</td></tr>
    <tr><td><code>movement_type</code></td><td>TEXT</td><td>NOT NULL CHECK (movement_type IN ('INITIAL_INVENTORY', 'RESTOCK_PURCHASE', 'TREATMENT_CONSUMPTION', 'MANUAL_ADJUSTMENT', 'DISCARDED_EXPIRED'))</td><td>Motif métier du mouvement de stock.</td></tr>
    <tr><td><code>quantity_change</code></td><td>REAL</td><td>NOT NULL</td><td>Variation nette (positive pour restock, négative pour consommation).</td></tr>
    <tr><td><code>stock_after</code></td><td>REAL</td><td>NOT NULL</td><td>Solde d'inventaire constaté immédiatement après mouvement.</td></tr>
    <tr><td><code>movement_date</code></td><td>TEXT</td><td>NOT NULL DEFAULT (datetime('now'))</td><td>Horodatage précis de la transaction (UTC).</td></tr>
    <tr><td><code>reason</code></td><td>TEXT</td><td>NULL</td><td>Remarque explicative ou référence de prise.</td></tr>
  </tbody>
</table>

<h3>8. Table <code>treatments</code> (Dossiers Thérapeutiques Globaux)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant unique du protocole de traitement.</td></tr>
    <tr><td><code>user_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES users(id) ON DELETE CASCADE</td><td>Patient concerné par le protocole.</td></tr>
    <tr><td><code>title</code></td><td>TEXT</td><td>NOT NULL</td><td>Intitulé usuel du traitement (ex: "Traitement Hypertension").</td></tr>
    <tr><td><code>pathology</code></td><td>TEXT</td><td>NULL</td><td>Pathologie ciblée ou indication thérapeutique.</td></tr>
    <tr><td><code>prescribing_doctor</code></td><td>TEXT</td><td>NULL</td><td>Nom du médecin à l'origine de l'ordonnance.</td></tr>
    <tr><td><code>start_date</code></td><td>TEXT</td><td>NOT NULL</td><td>Date de mise en route du traitement.</td></tr>
    <tr><td><code>end_date</code></td><td>TEXT</td><td>NULL</td><td>Date prévisionnelle de fin (NULL si traitement chronique).</td></tr>
    <tr><td><code>is_chronic</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 0</td><td>Définit si le traitement est suivi au long cours.</td></tr>
    <tr><td><code>status</code></td><td>TEXT</td><td>NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED'))</td><td>Statut de gestion du cycle de vie thérapeutique.</td></tr>
    <tr><td><code>is_deleted</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 0</td><td>Soft Delete préservant l'historique d'observance.</td></tr>
  </tbody>
</table>

<h3>9. Table <code>prescription_items</code> (Lignes de Médicaments Prescrits)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant de la ligne d'ordonnance.</td></tr>
    <tr><td><code>treatment_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES treatments(id) ON DELETE CASCADE</td><td>Traitement parent.</td></tr>
    <tr><td><code>medication_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES medications(id) ON DELETE RESTRICT</td><td>Médicament physique consommé (suppression interdite si lié).</td></tr>
    <tr><td><code>unit_dose</code></td><td>REAL</td><td>NOT NULL CHECK (unit_dose &gt; 0)</td><td>Nombre d'unités prescrites par prise (ex: 1 comprimé).</td></tr>
    <tr><td><code>unit_label</code></td><td>TEXT</td><td>NOT NULL</td><td>Libellé d'unité (comprimé, bouffée, gélule, cuillère).</td></tr>
    <tr><td><code>meal_condition</code></td><td>TEXT</td><td>NOT NULL DEFAULT 'INDIFFERENT'</td><td>Condition alimentaire (À jeun, Avant repas, Pendant...).</td></tr>
    <tr><td><code>instructions</code></td><td>TEXT</td><td>NULL</td><td>Consignes particulières du médecin (ex: "Boire un grand verre d'eau").</td></tr>
    <tr><td><code>is_prn</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 0</td><td>Traitement à la demande (« Pro Re Nata » si besoin).</td></tr>
    <tr><td><code>max_daily_doses_prn</code></td><td>INTEGER</td><td>NULL</td><td>Plafond journalier de sécurité si prise à la demande.</td></tr>
  </tbody>
</table>

<h3>10. Table <code>intake_schedules</code> (Règles Posologiques & Fréquence)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant de la règle de récurrence posologique.</td></tr>
    <tr><td><code>prescription_item_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES prescription_items(id) ON DELETE CASCADE</td><td>Ligne de prescription rattachée.</td></tr>
    <tr><td><code>schedule_type</code></td><td>TEXT</td><td>NOT NULL CHECK (schedule_type IN ('DAILY', 'CYCLIC', 'WEEKLY_DAYS', 'HOURLY_INTERVAL', 'AS_NEEDED_PRN'))</td><td>Type de récurrence temporelle.</td></tr>
    <tr><td><code>target_times_json</code></td><td>TEXT</td><td>NOT NULL</td><td>Tableau JSON des heures cibles programmées (ex: <code>["08:00", "20:00"]</code>).</td></tr>
    <tr><td><code>days_of_week_json</code></td><td>TEXT</td><td>NULL</td><td>Tableau JSON des jours actifs [1..7] (si hebdomadaire).</td></tr>
    <tr><td><code>interval_hours</code></td><td>INTEGER</td><td>NULL</td><td>Période horaire fixe (si répétition toutes les N heures).</td></tr>
  </tbody>
</table>

<h3>11. Table <code>planned_intakes</code> (Instances Prévisionnelles de Prise)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant de l'instance prévisionnelle ordonnancée.</td></tr>
    <tr><td><code>intake_schedule_id</code></td><td>TEXT</td><td>NOT NULL REFERENCES intake_schedules(id) ON DELETE CASCADE</td><td>Règle génératrice de l'instance.</td></tr>
    <tr><td><code>scheduled_datetime</code></td><td>TEXT</td><td>NOT NULL</td><td>Horodatage cible de la prise (ISO-8601 UTC).</td></tr>
    <tr><td><code>dose_to_take</code></td><td>REAL</td><td>NOT NULL</td><td>Quantité d'unités à absorber.</td></tr>
    <tr><td><code>tolerance_minutes</code></td><td>INTEGER</td><td>NOT NULL DEFAULT 60</td><td>Fenêtre de tolérance horaire avant marquage "manquée".</td></tr>
    <tr><td><code>status</code></td><td>TEXT</td><td>NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'NOTIFIED', 'TAKEN', 'MISSED', 'SNOOZED', 'SKIPPED'))</td><td>État d'avancement de l'instance.</td></tr>
  </tbody>
</table>

<h3>12. Table <code>intake_logs</code> (Journal Immuable des Ingestions Réelles)</h3>
<table>
  <thead>
    <tr>
      <th>Colonne</th>
      <th>Type SQLite</th>
      <th>Contraintes</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>TEXT</td><td>PRIMARY KEY</td><td>Identifiant du reçu immuable de prise.</td></tr>
    <tr><td><code>planned_intake_id</code></td><td>TEXT</td><td>NOT NULL UNIQUE REFERENCES planned_intakes(id) ON DELETE CASCADE</td><td>Lien 1-1 vers l'instance planifiée correspondante.</td></tr>
    <tr><td><code>actual_taken_datetime</code></td><td>TEXT</td><td>NOT NULL</td><td>Date et heure exactes de la validation physique de prise.</td></tr>
    <tr><td><code>actual_dose</code></td><td>REAL</td><td>NOT NULL</td><td>Quantité réellement avalée ou administrée.</td></tr>
    <tr><td><code>status</code></td><td>TEXT</td><td>NOT NULL CHECK (status IN ('TAKEN_ON_TIME', 'TAKEN_LATE', 'SKIPPED_INTENTIONALLY', 'MISSED_FORGOTTEN'))</td><td>Qualification clinique de l'exécution.</td></tr>
    <tr><td><code>notes</code></td><td>TEXT</td><td>NULL</td><td>Observations du patient (effets secondaires, circonstances).</td></tr>
    <tr><td><code>is_within_tolerance</code></td><td>INTEGER</td><td>NOT NULL</td><td>Vrai si la prise a eu lieu dans la tolérance médicale.</td></tr>
  </tbody>
</table>

<h3>13. Table <code>practitioners</code> & <code>health_facilities</code> (Soignants & Lieux)</h3>
<table>
  <thead>
    <tr>
      <th>Table</th>
      <th>Colonnes Principales</th>
      <th>Contraintes & Clés Étrangères</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>health_facilities</code></td>
      <td><code>id</code> (PK), <code>facility_name</code>, <code>address</code>, <code>building_floor</code>, <code>latitude</code>, <code>longitude</code>, <code>phone</code></td>
      <td>Coordonnées GPS avec contraintes de latitude (-90..90) et longitude (-180..180).</td>
      <td>Cabinets, hôpitaux, centres de santé où exercent les professionnels.</td>
    </tr>
    <tr>
      <td><code>practitioners</code></td>
      <td><code>id</code> (PK), <code>user_id</code> (FK users), <code>health_facility_id</code> (FK NULLABLE), <code>title</code>, <code>first_name</code>, <code>last_name</code>, <code>specialty</code>, <code>rpps_number</code>, <code>phone</code>, <code>email</code></td>
      <td><code>health_facility_id REFERENCES health_facilities(id) ON DELETE SET NULL</code></td>
      <td>Répertoire des soignants consultés par l'utilisateur.</td>
    </tr>
  </tbody>
</table>

<h3>14. Table <code>appointments</code> & <code>consultation_records</code> (Agenda & Comptes-Rendus)</h3>
<table>
  <thead>
    <tr>
      <th>Table</th>
      <th>Colonnes Principales</th>
      <th>Contraintes & Clés Étrangères</th>
      <th>Description Fonctionnelle</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>appointments</code></td>
      <td><code>id</code> (PK), <code>user_id</code> (FK), <code>practitioner_id</code> (FK), <code>health_facility_id</code> (FK NULLABLE), <code>start_datetime</code>, <code>duration_minutes</code>, <code>purpose</code>, <code>modality</code>, <code>teleconsult_url</code>, <code>status</code>, <code>reminder_48h_sent</code>, <code>reminder_2h_sent</code>, <code>is_deleted</code></td>
      <td><code>practitioner_id REFERENCES practitioners(id) ON DELETE RESTRICT</code>.<br><code>status CHECK IN ('SCHEDULED', 'CONFIRMED', 'RESCHEDULED', 'CANCELLED_BY_PATIENT', 'CANCELLED_BY_PRACTITIONER', 'COMPLETED', 'MISSED')</code></td>
      <td>Événements d'agenda médical et paramétrage des rappels de consultation.</td>
    </tr>
    <tr>
      <td><code>consultation_records</code></td>
      <td><code>id</code> (PK), <code>appointment_id</code> (FK UNIQUE), <code>actual_date</code>, <code>clinical_summary</code>, <code>doctor_advice</code>, <code>systolic_bp</code>, <code>diastolic_bp</code>, <code>recorded_weight_kg</code>, <code>resting_heart_rate_bpm</code>, <code>prescribed_exam_notes</code></td>
      <td><code>appointment_id REFERENCES appointments(id) ON DELETE CASCADE</code>.<br>Constantes tensionnelles avec CHECK raisonnables.</td>
      <td>Mémoire clinique de la consultation réalisée, constantes physiologiques et ordonnances reçues.</td>
    </tr>
  </tbody>
</table>

<h2>5.3 Politiques de Suppression et Stratégie d'Archivage (Soft Delete)</h2>
<p>La réglementation sur les données de santé exige la préservation de l'historique thérapeutique afin d'éviter la falsification des bilans d'observance passés :</p>
<ul>
  <li><strong>Suppression Physique en Cascade (<code>ON DELETE CASCADE</code>) :</strong> Réservée aux entités subsidiaires qui perdent toute signification sans leur parent : la suppression d'un compte <code>users</code> purge l'ensemble de ses tables associées (respect du droit à l'effacement RGPD). La suppression d'un <code>intake_schedule</code> purge ses <code>planned_intakes</code> non échues.</li>
  <li><strong>Suppression Restrictive (<code>ON DELETE RESTRICT</code>) :</strong> Appliquée pour empêcher la suppression d'un <code>medications</code> de l'inventaire s'il est actuellement référencé dans un <code>prescription_items</code> d'un traitement en cours. Le système impose à l'utilisateur de clôturer le traitement avant de retirer le médicament.</li>
  <li><strong>Suppression Logique (<code>Soft Delete</code> via <code>is_deleted = 1</code>) :</strong> Mise en œuvre sur les tables <code>medications</code>, <code>treatments</code> et <code>appointments</code>. Un traitement arrêté prématurément n'est pas effacé de la base : il est marqué archivé, ce qui garantit la pérennité intégrale du calcul d'observance historique sur les 12 mois écoulés.</li>
</ul>

<h2>5.4 Analyse Différentielle : Entités Métier vs Services vs Tables BDD</h2>
<table>
  <thead>
    <tr>
      <th style="width: 20%;">Dimension</th>
      <th style="width: 26%;">Entités Métier (Domain Layer)</th>
      <th style="width: 27%;">Services & Use Cases (Application Layer)</th>
      <th style="width: 27%;">Tables Relationnelles (Data / SQLite Layer)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Rôle Principal</strong></td>
      <td>Représenter les concepts fondamentaux du domaine médical et encapsuler les invariants et règles pures.</td>
      <td>Orchestrer l'exécution des scénarios d'usage, gérer les transactions et coordonner les flux techniques.</td>
      <td>Assurer la persistance durable, normalisée, chiffrée et indexée sur le disque du smartphone.</td>
    </tr>
    <tr>
      <td><strong>Immuabilité & Cycle de Vie</strong></td>
      <td>Modèles souvent immuables (Freezed/Dart), recréés via <code>copyWith()</code> lors des transitions d'état métier.</td>
      <td>Composants logiciels sans état (stateless singletons) injectés via GetIt ou Riverpod.</td>
      <td>Lignes de base de données mutables via requêtes SQL ACID avec intégrité référentielle stricte.</td>
    </tr>
    <tr>
      <td><strong>Dépendances Logicielles</strong></td>
      <td><strong>Aucune dépendance externe.</strong> Code Dart pur indépendant de Flutter, d'OS, de base de données ou de réseau.</td>
      <td>Dépendent uniquement des interfaces abstraites de repositories (principe d'inversion des dépendances).</td>
      <td>Fortement dépendantes de l'environnement SQL, de SQLite, de SQLCipher et des types de colonnes natifs.</td>
    </tr>
    <tr>
      <td><strong>Exemple Concret</strong></td>
      <td><code>Treatment.pauseTreatment()</code> valide la transition d'état et émet un nouvel état métier cohérent.</td>
      <td><code>RecordMedicationIntakeUseCase</code> pilote la transaction SQLite, décrémente le stock et annule l'alarme locale.</td>
      <td>Table <code>treatments</code> stocke <code>status = 'PAUSED'</code> et <code>is_deleted = 0</code> avec contraintes CHECK physiques.</td>
    </tr>
  </tbody>
</table>
''';
