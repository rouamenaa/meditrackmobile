const String section6ComplementaryDiagramsHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">6</span> Diagrammes UML Complémentaires</h1>
<p>Cette section enrichit la vue structurelle par l'analyse dynamique des comportements, des interactions temporelles et des états du système MediTrack.</p>

<h2>6.1 Diagramme Global de Cas d'Utilisation (Use Cases)</h2>
<p>Le système interagit avec trois acteurs : le <strong>Patient (Utilisateur Principal)</strong>, le <strong>Moteur d'Ordonnancement Local (Système d'Alarmes)</strong>, et les <strong>Capteurs / APIs de Santé Locaux (Health Connect / HealthKit)</strong>.</p>

<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.1 — Diagramme des Cas d'Utilisation Système</span>
    <span class="diagram-type">UML Use Case Diagram</span>
  </div>
  <div class="mermaid">
flowchart LR
    subgraph Acteurs
        Patient((Patient / Usager))
        Scheduler((Ordonnanceur Local OS))
        HealthSensors((Capteurs / APIs Sante))
    end

    subgraph "MediTrack Mobile"
        subgraph "Module 1 - Securite & Profil"
            UC_Auth["S'authentifier (Biometrie / PIN / Pwd)"]
            UC_Profile["Mettre a jour profil medical & urgences"]
            UC_Prefs["Configurer preferences & mode discret"]
        end

        subgraph "Module 2 - Activite Physique"
            UC_ActManual["Saisir activite physique manuelle"]
            UC_ActSync["Synchroniser activites & pas"]
            UC_Goal["Definir & suivre objectifs d'effort (OMS)"]
        end

        subgraph "Module 3 - Inventaire Medicaments"
            UC_MedAdd["Enregistrer medicament & lot"]
            UC_StockAlert["Recevoir alerte peremption / stock bas"]
            UC_Restock["Reapprovisionner boite de medicaments"]
        end

        subgraph "Module 4 - Traitements & Prises"
            UC_TreatAdd["Creer traitement & posologie"]
            UC_IntakeTake["Valider prise de medicament"]
            UC_IntakeSnooze["Reporter prise (Snooze 15 min)"]
            UC_Adherence["Consulter taux d'observance"]
        end

        subgraph "Module 5 - Rendez-vous"
            UC_ApptBook["Planifier rendez-vous medical"]
            UC_ApptRemind["Recevoir rappel RDV (J-2 / H-2)"]
            UC_ConsultLog["Consigner compte-rendu & ordonnance"]
        end
    end

    Patient --> UC_Auth
    Patient --> UC_Profile
    Patient --> UC_Prefs
    Patient --> UC_ActManual
    Patient --> UC_Goal
    Patient --> UC_MedAdd
    Patient --> UC_Restock
    Patient --> UC_TreatAdd
    Patient --> UC_IntakeTake
    Patient --> UC_IntakeSnooze
    Patient --> UC_Adherence
    Patient --> UC_ApptBook
    Patient --> UC_ConsultLog

    HealthSensors --> UC_ActSync
    Scheduler --> UC_StockAlert
    Scheduler --> UC_IntakeTake
    Scheduler --> UC_ApptRemind
  </div>
  <div class="diagram-caption">Figure 6.1 — Cartographie complète des cas d'utilisation de MediTrack et de leurs acteurs initiateurs.</div>
</div>

<div class="page-break"></div>

<h2>6.2 Diagrammes de Séquence Systémiques</h2>

<h3>Séquence 1 : Authentification Sécurisée & Déverrouillage Biométrique</h3>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.2 — Diagramme de Séquence : Authentification & Déverrouillage Biométrique</span>
    <span class="diagram-type">UML Sequence Diagram</span>
  </div>
  <div class="mermaid">
sequenceDiagram
    autonumber
    actor Patient
    participant UI as LoginScreen (Flutter)
    participant Bloc as AuthBloc
    participant LocalAuth as BiometricService (OS)
    participant SecureStore as FlutterSecureStorage
    participant Repo as UserRepository
    participant DB as SQLite / SQLCipher

    Patient->>UI: Ouvre l'application MediTrack
    UI->>Bloc: AppCheckSessionEvent()
    Bloc->>Repo: getLastActiveSession()
    Repo-->>Bloc: SessionLocked(userId, isBiometricEnabled=true)
    Bloc-->>UI: AuthStatePromptBiometric()

    UI->>LocalAuth: authenticateWithBiometrics(title: "MediTrack")
    LocalAuth-->>Patient: Invite capteur biométrique (Empreinte / Face ID)
    Patient->>LocalAuth: Présente empreinte biométrique valide
    LocalAuth-->>UI: AuthenticationSuccess(true)

    UI->>Bloc: BiometricAuthSucceededEvent()
    Bloc->>SecureStore: read(key: "master_db_aes_key")
    SecureStore-->>Bloc: rawAesKeyBytes
    Bloc->>DB: openDatabase("meditrack.db", password: rawAesKeyBytes)
    DB-->>Bloc: DatabaseHandle(OPEN_DECRYPTED)
    Bloc->>Repo: recordSuccessfulLogin(userId)
    Repo->>DB: UPDATE users SET last_login_at = datetime('now'), failed_attempts = 0
    Bloc-->>UI: AuthStateAuthenticated(userProfile)
    UI-->>Patient: Affiche Dashboard Principal avec données à jour
  </div>
  <div class="diagram-caption">Figure 6.2 — Flux d'authentification biométrique avec déverrouillage de la clé maîtresse AES-256.</div>
</div>

<div class="page-break"></div>

<h3>Séquence 2 : Création d'un Traitement Complexe & Ordonnancement Prévisionnel</h3>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.3 — Diagramme de Séquence : Création d'un Traitement et Ordonnancement</span>
    <span class="diagram-type">UML Sequence Diagram</span>
  </div>
  <div class="mermaid">
sequenceDiagram
    autonumber
    actor Patient
    participant UI as TreatmentFormScreen
    participant Bloc as TreatmentBloc
    participant UseCase as ScheduleTreatmentUseCase
    participant TreatRepo as TreatmentRepository
    participant DB as SQLite DB
    participant AlarmMgr as ExactAlarmScheduler (OS)

    Patient->>UI: Saisit traitement ("Hypertension", Médicament: "Kardegic 75mg", Heure: "08:00", Durée: Chronique)
    Patient->>UI: Clique sur "Valider le traitement"
    UI->>Bloc: CreateTreatmentEvent(treatmentDto)
    Bloc->>UseCase: execute(treatment, prescriptionItems)

    UseCase->>TreatRepo: saveTreatment(treatment)
    TreatRepo->>DB: INSERT INTO treatments (...) VALUES (...)
    TreatRepo->>DB: INSERT INTO prescription_items (...) VALUES (...)
    TreatRepo->>DB: INSERT INTO intake_schedules (...) VALUES (...)

    Note over UseCase: Génération de l'horizon prévisionnel (14 jours glissants)
    UseCase->>UseCase: generatePlannedIntakes(from: Today, to: Today + 14d)

    loop Pour chaque jour de l'horizon
        UseCase->>TreatRepo: savePlannedIntake(plannedIntake)
        TreatRepo->>DB: INSERT INTO planned_intakes (scheduled_datetime, status='SCHEDULED', ...)
        UseCase->>AlarmMgr: scheduleExactAlarm(id: intake.id, triggerTime: 08:00, title: "MediTrack Prise")
        AlarmMgr-->>UseCase: AlarmRegistered(exactIntentId)
    end

    UseCase-->>Bloc: TreatmentScheduledSuccess()
    Bloc-->>UI: TreatmentStateCreated()
    UI-->>Patient: Confirmation visuelle + Planning mis à jour dans le calendrier
  </div>
  <div class="diagram-caption">Figure 6.3 — Création d'un protocole thérapeutique et ordonnancement prédictif des alarmes exactes.</div>
</div>

<div class="page-break"></div>

<h3>Séquence 3 : Déclenchement d'Alarme, Validation de Prise & Décrémentation de Stock</h3>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.4 — Diagramme de Séquence : Notification de Rappel et Validation de Prise</span>
    <span class="diagram-type">UML Sequence Diagram</span>
  </div>
  <div class="mermaid">
sequenceDiagram
    autonumber
    participant OS as Système Android / iOS
    participant Push as LocalNotificationReceiver
    actor Patient
    participant UI as Dashboard / QuickAction
    participant UseCase as RecordMedicationIntakeUseCase
    participant TreatRepo as TreatmentRepository
    participant MedRepo as MedicationRepository
    participant DB as SQLite DB

    OS->>Push: Déclenchement alarme exacte (08:00)
    Push->>Patient: Notification : "MediTrack : Prise de Kardegic 75mg prévue" (Boutons: [Prendre] [Reporter])

    alt Action rapide via notification ou écran
        Patient->>Push: Appuie sur le bouton d'action [Prendre]
        Push->>UseCase: execute(plannedIntakeId, actualDose: 1.0, timestamp: now())
    else Ouverture de l'application
        Patient->>UI: Valide la prise sur le Dashboard
        UI->>UseCase: execute(plannedIntakeId, actualDose: 1.0, timestamp: now())
    end

    critical Transaction ACID d'Enregistrement de Prise
        UseCase->>DB: BEGIN TRANSACTION
        UseCase->>TreatRepo: markIntakeTaken(plannedIntakeId)
        TreatRepo->>DB: UPDATE planned_intakes SET status = 'TAKEN' WHERE id = ?
        UseCase->>TreatRepo: recordLog(intakeLog)
        TreatRepo->>DB: INSERT INTO intake_logs (actual_taken_datetime, actual_dose, status, is_within_tolerance) VALUES (...)
        UseCase->>MedRepo: decrementStock(medicationId, amount: 1.0)
        MedRepo->>DB: UPDATE medications SET current_stock = current_stock - 1.0 WHERE id = ?
        MedRepo->>DB: INSERT INTO stock_movements (movement_type='TREATMENT_CONSUMPTION', quantity=-1.0, ...) VALUES (...)
        UseCase->>DB: COMMIT TRANSACTION
    end

    opt Si Stock Rémanent <= min_stock_threshold
        MedRepo->>Push: Émettre alerte de réapprovisionnement ("Stock critique : Kardegic 75mg restant : 3 comprimés")
        Push-->>Patient: Alerte Stock Bas dans le centre de notifications
    end

    UseCase-->>UI: IntakeRecordedSuccessfully()
    UI-->>Patient: Jauge d'observance actualisée (Taux recalculé en temps réel)
  </div>
  <div class="diagram-caption">Figure 6.4 — Cycle complet de prise : alarme, validation atomique et contrôle du seuil d'inventaire.</div>
</div>

<div class="page-break"></div>

<h3>Séquence 4 : Cycle de Rendez-vous Médical (Planification, Rappels, Consultation)</h3>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.5 — Diagramme de Séquence : Cycle de Vie d'un Rendez-vous Médical</span>
    <span class="diagram-type">UML Sequence Diagram</span>
  </div>
  <div class="mermaid">
sequenceDiagram
    autonumber
    actor Patient
    participant UI as AppointmentScreen
    participant ApptRepo as AppointmentRepository
    participant DB as SQLite DB
    participant AlarmMgr as ExactAlarmScheduler (OS)
    actor Practitioner as Médecin Spécialiste

    Patient->>UI: Planifie RDV (Dr. Morel - Cardiologue, 15 Nov à 14h30, Motif: "Bilan tension")
    UI->>ApptRepo: saveAppointment(appointment)
    ApptRepo->>DB: INSERT INTO appointments (...) VALUES (...)

    ApptRepo->>AlarmMgr: scheduleExactAlarm(id: appt.id + "_48h", trigger: 13 Nov 14h30, title: "Rappel RDV J-2")
    ApptRepo->>AlarmMgr: scheduleExactAlarm(id: appt.id + "_2h", trigger: 15 Nov 12h30, title: "Rappel RDV H-2 + Itinéraire")

    Note over AlarmMgr, Patient: 13 Novembre à 14h30 (J-2)
    AlarmMgr-->>Patient: Alerte : "Rappel MediTrack : Consultation Dr. Morel dans 48h. Avez-vous vos bilans ?"

    Note over AlarmMgr, Patient: 15 Novembre à 12h30 (H-2)
    AlarmMgr-->>Patient: Alerte : "Consultation dans 2 heures à la Clinique du Parc. [Itinéraire]"

    Note over Patient, Practitioner: Consultation clinique réalisée au cabinet
    Patient->>UI: Ouvre le RDV et clique sur "Enregistrer compte-rendu de consultation"
    Patient->>UI: Saisit : TA: 130/80 mmHg, Poids: 76.5 kg, Conseil: "Poursuivre marche 30 min/jour"
    UI->>ApptRepo: saveConsultationRecord(consultationRecord)
    ApptRepo->>DB: UPDATE appointments SET status = 'COMPLETED' WHERE id = ?
    ApptRepo->>DB: INSERT INTO consultation_records (...) VALUES (...)
    UI-->>Patient: Consultation archivée dans le dossier médical
  </div>
  <div class="diagram-caption">Figure 6.5 — Cycle complet d'un rendez-vous médical avec ses notifications préalables échelonnées.</div>
</div>

<div class="page-break"></div>

<h2>6.3 Diagramme d'Activité : Journée Type d'un Patient sous MediTrack</h2>
<p>Ce diagramme d'activité modélise le parcours quotidien typique d'un utilisateur de MediTrack, illustrant l'intégration harmonieuse des cinq modules fonctionnels au rythme de vie du patient :</p>

<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.6 — Diagramme d'Activité : Parcours Journalier du Patient</span>
    <span class="diagram-type">UML Activity Diagram</span>
  </div>
  <div class="mermaid">
stateDiagram-v2
    [*] --> ReveilMatin : 07h30 - Reveil
    ReveilMatin --> AlarmePriseMatin : 08h00 - Alarme locale exacte
    AlarmePriseMatin --> DecisionPrise : Notification recue

    state DecisionPrise <<choice>>
    DecisionPrise --> ValidationPrise : Patient confirme la prise
    DecisionPrise --> SnoozePrise : Patient indisponible (Snooze 15 min)

    SnoozePrise --> AlarmePriseMatin : Apres 15 min

    ValidationPrise --> MajStockObservance : Transaction atomique (Stock - 1)
    MajStockObservance --> ActivitePhysiqueMidi : 12h30 - Marche active 35 min
    ActivitePhysiqueMidi --> CalculDepenseMET : Calcul automatique MET (3.8) & Calories
    CalculDepenseMET --> VerificationObjectif : Comparaison avec cible hebdo OMS

    VerificationObjectif --> AlerteApresMidi : 14h00 - Alerte RDV J-2 ou Stock
    AlerteApresMidi --> PriseSoir : 20h00 - Rappel prise du soir
    PriseSoir --> ConsultationBilan : 21h30 - Consultation Dashboard & Jauge
    ConsultationBilan --> VerrouillageNuit : 22h00 - Mode discret / Nuit silencieuse
    VerrouillageNuit --> [*] : Fin de journee
  </div>
  <div class="diagram-caption">Figure 6.6 — Enchaînement chronologique des activités quotidiennes assistées par MediTrack.</div>
</div>

<div class="page-break"></div>

<h2>6.4 Diagrammes d'États (Statecharts)</h2>

<h3>Machine d'État du Traitement (<code>Treatment</code>)</h3>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.7 — Machine d'État : Cycle de Vie d'un Traitement</span>
    <span class="diagram-type">UML State Machine</span>
  </div>
  <div class="mermaid">
stateDiagram-v2
    [*] --> ACTIVE : Creation du traitement par le patient
    ACTIVE --> PAUSED : Suspension temporaire (pause medicale)
    PAUSED --> ACTIVE : Reprise du traitement (recalcul planning)
    ACTIVE --> COMPLETED : Echeance de date de fin atteinte (succes)
    ACTIVE --> CANCELLED : Arret anticipe (effet indesirable / avis medecin)
    PAUSED --> CANCELLED : Arret definitif pendant pause
    COMPLETED --> [*] : Archive dans historique d'observance
    CANCELLED --> [*] : Archive avec motif
  </div>
  <div class="diagram-caption">Figure 6.7 — Cycle de vie du protocole de traitement.</div>
</div>

<h3>Machine d'État d'une Prise Prévue (<code>PlannedIntake</code>)</h3>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.8 — Machine d'État : Cycle de Vie d'une Prise Prévue</span>
    <span class="diagram-type">UML State Machine</span>
  </div>
  <div class="mermaid">
stateDiagram-v2
    [*] --> SCHEDULED : Instance generee par l'ordonnanceur
    SCHEDULED --> NOTIFIED : Heure cible atteinte (alarme declenchee)
    NOTIFIED --> SNOOZED : Patient clique sur "Reporter 15 min"
    SNOOZED --> NOTIFIED : Nouvelle echeance d'alarme
    NOTIFIED --> TAKEN : Prise validee dans la tolerance (+/- 60 min)
    NOTIFIED --> MISSED : Delai de tolerance expire sans reponse
    NOTIFIED --> SKIPPED : Patient saute volontairement la prise
    TAKEN --> [*] : IntakeLog persiste & Stock decremente
    MISSED --> [*] : Trace d'oubli classee en non-observance
    SKIPPED --> [*] : Trace de saut motivee classee
  </div>
  <div class="diagram-caption">Figure 6.8 — Transitions d'état d'une instance prévisionnelle de prise médicamenteuse.</div>
</div>

<h3>Machine d'État d'un Rendez-vous Médical (<code>Appointment</code>)</h3>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.9 — Machine d'État : Cycle de Vie d'un Rendez-vous Médical</span>
    <span class="diagram-type">UML State Machine</span>
  </div>
  <div class="mermaid">
stateDiagram-v2
    [*] --> SCHEDULED : Planification initiale dans l'agenda
    SCHEDULED --> CONFIRMED : Confirmation par le praticien ou patient
    SCHEDULED --> RESCHEDULED : Changement d'horaire (recalcul des rappels J-2/H-2)
    CONFIRMED --> RESCHEDULED : Changement d'horaire
    SCHEDULED --> CANCELLED_BY_PATIENT : Annulation par le patient
    SCHEDULED --> CANCELLED_BY_PRACTITIONER : Annulation par le cabinet
    CONFIRMED --> COMPLETED : Consultation realisee avec succes
    CONFIRMED --> MISSED : Patient absent non excuse
    COMPLETED --> [*] : Compte-rendu clinique renseigne
    CANCELLED_BY_PATIENT --> [*] : Alarmes revoquees
    CANCELLED_BY_PRACTITIONER --> [*] : Alarmes revoquees
    MISSED --> [*] : Historique de non-presentation
  </div>
  <div class="diagram-caption">Figure 6.9 — États possibles d'une consultation médicale planifiée.</div>
</div>

<div class="page-break"></div>

<h2>6.5 Diagramme de Composants : Architecture en Couches Flutter</h2>
<p>L'implémentation logicielle adopte les principes de la <strong>Clean Architecture</strong>, garantissant l'indépendance de la logique métier vis-à-vis du framework d'affichage et des spécificités des systèmes d'exploitation :</p>

<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 6.10 — Diagramme de Composants en Couches (Clean Architecture)</span>
    <span class="diagram-type">UML Component Diagram</span>
  </div>
  <div class="mermaid">
flowchart TB
    subgraph PRESENTATION ["1. Couche Présentation (Flutter UI & State Management)"]
        UI_Screens["Flutter Widgets & Screens (Dashboard, Forms, Calendar)"]
        UI_Blocs["BLoCs & Cubits (AuthBloc, TreatmentBloc, ActivityBloc, ApptBloc)"]
        UI_Screens --> UI_Blocs
    end

    subgraph DOMAIN ["2. Couche Domaine (Pure Dart — Règle Métier Absolue)"]
        UseCases["Use Cases / Interactors (RecordIntake, ScheduleTreatment, CalculateMET)"]
        Entities["Entités Métier & Value Objects (User, Medication, Treatment, Appointment)"]
        RepoInterfaces["Interfaces de Repositories (ITreatmentRepo, IMedicationRepo...)"]
        UseCases --> Entities
        UseCases --> RepoInterfaces
    end

    subgraph DATA ["3. Couche Données (Data Layer — Implémentations & DTOs)"]
        RepoImpl["Repositories Implémentés (TreatmentRepoImpl, MedicationRepoImpl...)"]
        Mappers["Mappers & DTOs (MedicationModel, TreatmentDto <--> Entities)"]
        DataSourcesLocal["Local Data Sources (SQLite / SQLCipher Helper, SecureStore)"]
        DataSourcesSync["Sync / Sensor Adapters (HealthConnectAdapter, HealthKitAdapter)"]
        RepoImpl --> RepoInterfaces
        RepoImpl --> Mappers
        RepoImpl --> DataSourcesLocal
        RepoImpl --> DataSourcesSync
    end

    subgraph PLATFORM ["4. Couche Plateforme & Matériel (Hardware & OS Services)"]
        SQLCipherDriver["Driver SQLite / SQLCipher (Chiffrement AES-256)"]
        AlarmService["flutter_local_notifications (AlarmClock Exact Scheduler)"]
        Biometrics["local_auth (BiometricPrompt / Touch ID / Face ID)"]
        SecureStoragePlugin["flutter_secure_storage (Android Keystore / iOS Keychain)"]
        DataSourcesLocal --> SQLCipherDriver
        DataSourcesLocal --> SecureStoragePlugin
        RepoImpl --> AlarmService
        UI_Blocs --> Biometrics
    end

    UI_Blocs --> UseCases
  </div>
  <div class="diagram-caption">Figure 6.10 — Composants logiciels et flux unidirectionnel des dépendances vers le Domaine.</div>
</div>
''';
