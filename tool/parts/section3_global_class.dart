const String section3GlobalClassHtml = r'''
<div class="landscape">
  <h1><span class="chapter-num">3</span> Diagramme Global de Classes UML 2.5</h1>
  <p>Ce diagramme systémique présente la modélisation objet globale du domaine <strong>MediTrack</strong>. Il fédère les cinq modules fonctionnels, leurs entités maîtresses, leurs attributs typés, leurs opérations majeures et la totalité des associations métier avec cardinalités formellement justifiées.</p>

  <div class="diagram-container">
    <div class="diagram-header">
      <span class="diagram-title">Figure 3.1 — Diagramme Global des Entités Métier (Modèle de Domaine UML 2.5)</span>
      <span class="diagram-type">UML Class Diagram</span>
    </div>
    <div class="mermaid">
classDiagram
    direction LR

    %% MODULE 1: AUTH & PROFIL
    class User {
        +UUID id
        +String email
        +String passwordHash
        +String salt
        +String pinHash
        +Boolean isBiometricEnabled
        +DateTime createdAt
        +DateTime lastLoginAt
        +authenticate(password) Boolean
        +verifyPin(pin) Boolean
        +updatePassword(oldPwd, newPwd)
        +enableBiometrics()
    }

    class PatientProfile {
        +UUID id
        +UUID userId
        +String firstName
        +String lastName
        +DateTime birthDate
        +BiologicalSex sex
        +Double heightCm
        +Double weightKg
        +BloodGroup bloodGroup
        +List~String~ allergies
        +List~String~ medicalHistory
        +String emergencyContactName
        +String emergencyContactPhone
        +calculateBmi() Double
        +getAge() int
    }

    class UserPreferences {
        +UUID id
        +UUID userId
        +Boolean isDiscreteMode
        +Boolean enableSound
        +Boolean enableVibration
        +String quietHoursStart
        +String quietHoursEnd
        +int appointmentReminderHoursDefault
        +updateQuietHours(start, end)
    }

    %% MODULE 2: ACTIVITE PHYSIQUE
    class PhysicalActivity {
        +UUID id
        +UUID userId
        +ActivityType activityType
        +DateTime startDateTime
        +int durationMinutes
        +Double distanceKm
        +ActivityIntensity intensity
        +int rpeScore
        +Double caloriesBurned
        +int avgHeartRateBpm
        +String notes
        +DataSource source
        +calculateEstimatedCalories(weightKg) Double
    }

    class ActivityGoal {
        +UUID id
        +UUID userId
        +GoalFrequency frequency
        +int targetDurationMinutes
        +Double targetCalories
        +int targetSteps
        +Boolean isActive
        +calculateProgress(actualDuration) Double
    }

    %% MODULE 3: MEDICAMENTS
    class Medication {
        +UUID id
        +UUID userId
        +String commercialName
        +String genericNameDci
        +String regulatoryCodeCis
        +Double dosageValue
        +String dosageUnit
        +GalenicForm form
        +AdministrationRoute route
        +Double currentStock
        +Double minStockThreshold
        +DateTime expiryDate
        +String batchNumber
        +isLowStock() Boolean
        +isExpired() Boolean
        +daysUntilExpiry() int
        +decrementStock(quantity)
        +restock(quantity, newExpiry)
    }

    class StockMovement {
        +UUID id
        +UUID medicationId
        +MovementType movementType
        +Double quantityChange
        +Double stockAfter
        +DateTime movementDate
        +String reason
    }

    %% MODULE 4: TRAITEMENTS & OBSERVANCE
    class Treatment {
        +UUID id
        +UUID userId
        +String title
        +String pathology
        +String prescribingDoctor
        +DateTime startDate
        +DateTime endDate
        +Boolean isChronic
        +TreatmentStatus status
        +String generalInstructions
        +pauseTreatment()
        +resumeTreatment()
        +completeTreatment()
    }

    class PrescriptionItem {
        +UUID id
        +UUID treatmentId
        +UUID medicationId
        +Double unitDose
        +String unitLabel
        +MealCondition mealCondition
        +String instructions
        +Boolean isPrn
        +int maxDailyDosesPrn
    }

    class IntakeSchedule {
        +UUID id
        +UUID prescriptionItemId
        +ScheduleType scheduleType
        +List~String~ targetTimes
        +List~int~ daysOfWeek
        +int intervalHours
        +generatePlannedIntakes(fromDate, toDate)
    }

    class PlannedIntake {
        +UUID id
        +UUID intakeScheduleId
        +DateTime scheduledDateTime
        +Double doseToTake
        +int toleranceMinutes
        +IntakeStatus status
        +markAsTaken(actualDose)
        +markAsMissed()
        +snooze(minutes)
    }

    class IntakeLog {
        +UUID id
        +UUID plannedIntakeId
        +DateTime actualTakenDateTime
        +Double actualDose
        +IntakeLogStatus status
        +String notes
        +Boolean isWithinTolerance
    }

    %% MODULE 5: RENDEZ-VOUS MEDICAUX
    class Practitioner {
        +UUID id
        +UUID userId
        +String title
        +String firstName
        +String lastName
        +String specialty
        +String rppsNumber
        +String phone
        +String email
        +getFullName() String
    }

    class HealthFacility {
        +UUID id
        +String facilityName
        +String address
        +String buildingFloor
        +Double latitude
        +Double longitude
        +String phone
    }

    class Appointment {
        +UUID id
        +UUID userId
        +UUID practitionerId
        +UUID healthFacilityId
        +DateTime startDateTime
        +int durationMinutes
        +String purpose
        +AppointmentModality modality
        +String teleconsultUrl
        +AppointmentStatus status
        +Boolean reminder48hSent
        +Boolean reminder2hSent
        +confirm()
        +cancel(reason)
        +reschedule(newDateTime)
        +markCompleted()
    }

    class ConsultationRecord {
        +UUID id
        +UUID appointmentId
        +DateTime actualDate
        +String clinicalSummary
        +String doctorAdvice
        +Double systolicBp
        +Double diastolicBp
        +Double recordedWeightKg
        +int restingHeartRateBpm
        +String prescribedExamNotes
    }

    %% NOTIFICATIONS TRANSVERSALES
    class NotificationAlert {
        +UUID id
        +UUID userId
        +String title
        +String body
        +DateTime triggerDateTime
        +NotificationType alertType
        +UUID targetEntityId
        +Boolean isDelivered
        +Boolean isDismissed
        +schedule()
        +cancel()
    }

    %% ASSOCIATIONS & RELATIONS
    User "1" *-- "1" PatientProfile : possède >
    User "1" *-- "1" UserPreferences : configure >
    User "1" o-- "0..*" PhysicalActivity : enregistre >
    User "1" o-- "0..*" ActivityGoal : définit >
    User "1" o-- "0..*" Medication : gère >
    User "1" o-- "0..*" Treatment : suit >
    User "1" o-- "0..*" Practitioner : consulte >
    User "1" o-- "0..*" Appointment : planifie >
    User "1" o-- "0..*" NotificationAlert : reçoit >

    Medication "1" *-- "0..*" StockMovement : trace >

    Treatment "1" *-- "1..*" PrescriptionItem : contient >
    PrescriptionItem "0..*" --> "1" Medication : référence >
    PrescriptionItem "1" *-- "1..*" IntakeSchedule : planifie via >
    IntakeSchedule "1" o-- "0..*" PlannedIntake : génère >
    PlannedIntake "1" <-- "0..1" IntakeLog : trace l'ingestion >
    IntakeLog "0..1" ..> "1" StockMovement : déclenche >

    Practitioner "0..*" --> "0..1" HealthFacility : exerce dans >
    Appointment "0..*" --> "1" Practitioner : concerne >
    Appointment "0..*" --> "0..1" HealthFacility : a lieu à >
    Appointment "1" *-- "0..1" ConsultationRecord : produit >

    PlannedIntake "1" ..> "0..*" NotificationAlert : programme >
    Appointment "1" ..> "0..*" NotificationAlert : programme >
    </div>
    <div class="diagram-caption">Figure 3.1 — Vue synthétique des 17 classes métier de MediTrack et de leurs relations structurelles en UML 2.5.</div>
  </div>
</div>

<div class="page-break"></div>

<h2>3.2 Dictionnaire des Associations Inter-Modules et Justification des Cardinalités</h2>
<p>Chaque relation modélisée dans le diagramme global répond à une exigence métier précise et respecte des cardinalités formellement justifiées :</p>

<table>
  <thead>
    <tr>
      <th style="width: 22%;">Association / Relation</th>
      <th style="width: 14%;">Type UML</th>
      <th style="width: 14%;">Cardinalités</th>
      <th style="width: 50%;">Justification Métier et Règle d'Invariance</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>User &harr; PatientProfile</strong></td>
      <td>Composition (<code>*--</code>)</td>
      <td><code>1 &harr; 1</code></td>
      <td>Chaque utilisateur possède exactement un profil médical. La destruction du compte utilisateur entraîne la destruction en cascade du profil. Un profil ne peut exister sans son utilisateur rattaché.</td>
    </tr>
    <tr>
      <td><strong>User &harr; UserPreferences</strong></td>
      <td>Composition (<code>*--</code>)</td>
      <td><code>1 &harr; 1</code></td>
      <td>Un compte utilisateur est indissociable de sa grille de préférences de notification et de confidentialité. Les préférences sont initialisées avec des valeurs par défaut sécurisées dès l'enrôlement.</td>
    </tr>
    <tr>
      <td><strong>User &harr; PhysicalActivity</strong></td>
      <td>Agrégation (<code>o--</code>)</td>
      <td><code>1 &harr; 0..*</code></td>
      <td>Un utilisateur peut n'avoir enregistré aucune activité (nouvel utilisateur) ou en posséder un historique illimité. L'activité appartient au patient mais n'a pas de lien de cycle de vie direct avec d'autres entités.</td>
    </tr>
    <tr>
      <td><strong>User &harr; Medication</strong></td>
      <td>Agrégation (<code>o--</code>)</td>
      <td><code>1 &harr; 0..*</code></td>
      <td>L'utilisateur gère son armoire à pharmacie personnelle. L'inventaire peut être initialement vide et s'enrichir au fil des acquisitions.</td>
    </tr>
    <tr>
      <td><strong>Medication &harr; StockMovement</strong></td>
      <td>Composition (<code>*--</code>)</td>
      <td><code>1 &harr; 0..*</code></td>
      <td>Chaque mouvement d'inventaire (entrée, consommation, rebut) est rigoureusement rattaché à une spécialité médicamenteuse spécifique. La suppression d'un médicament archive ses mouvements pour la traçabilité.</td>
    </tr>
    <tr>
      <td><strong>User &harr; Treatment</strong></td>
      <td>Agrégation (<code>o--</code>)</td>
      <td><code>1 &harr; 0..*</code></td>
      <td>Un patient peut n'avoir aucun traitement en cours ou suivre plusieurs protocoles de soins simultanés (poly-pathologies).</td>
    </tr>
    <tr>
      <td><strong>Treatment &harr; PrescriptionItem</strong></td>
      <td>Composition (<code>*--</code>)</td>
      <td><code>1 &harr; 1..*</code></td>
      <td>Un traitement ne peut exister à vide : il contient au minimum un médicament prescrit. Si le traitement est supprimé, ses lignes de prescription le sont également.</td>
    </tr>
    <tr>
      <td><strong>PrescriptionItem &harr; Medication</strong></td>
      <td>Association dirigée (<code>--&gt;</code>)</td>
      <td><code>0..* &harr; 1</code></td>
      <td>Chaque ligne de prescription fait référence à un médicament physique de l'armoire à pharmacie. Un même médicament peut être prescrit dans plusieurs traitements successifs.</td>
    </tr>
    <tr>
      <td><strong>PrescriptionItem &harr; IntakeSchedule</strong></td>
      <td>Composition (<code>*--</code>)</td>
      <td><code>1 &harr; 1..*</code></td>
      <td>La ligne prescrite impose au moins une règle posologique d'ordonnancement (fréquence et heures de prises).</td>
    </tr>
    <tr>
      <td><strong>IntakeSchedule &harr; PlannedIntake</strong></td>
      <td>Agrégation (<code>o--</code>)</td>
      <td><code>1 &harr; 0..*</code></td>
      <td>L'ordonnanceur génère les instances de prises futures sur un horizon de 14 jours glissants à partir de la règle programmée.</td>
    </tr>
    <tr>
      <td><strong>PlannedIntake &harr; IntakeLog</strong></td>
      <td>Association (<code>&harr;</code>)</td>
      <td><code>1 &harr; 0..1</code></td>
      <td>Une prise planifiée n'a initialement aucun journal (<code>0</code>). Dès que le patient interagit pour la valider ou la différer, un unique <code>IntakeLog</code> (<code>1</code>) immuable est consigné.</td>
    </tr>
    <tr>
      <td><strong>IntakeLog &harr; StockMovement</strong></td>
      <td>Dépendance d'effet (<code>..&gt;</code>)</td>
      <td><code>0..1 &harr; 1</code></td>
      <td>La validation effective d'une prise médicamenteuse engendre une décrémentation automatique du stock rémanent modélisée par un mouvement d'inventaire de type <code>TREATMENT_CONSUMPTION</code>.</td>
    </tr>
    <tr>
      <td><strong>User &harr; Appointment</strong></td>
      <td>Agrégation (<code>o--</code>)</td>
      <td><code>1 &harr; 0..*</code></td>
      <td>L'utilisateur gère son agenda de consultations médicales.</td>
    </tr>
    <tr>
      <td><strong>Appointment &harr; Practitioner</strong></td>
      <td>Association dirigée (<code>--&gt;</code>)</td>
      <td><code>0..* &harr; 1</code></td>
      <td>Un rendez-vous est obligatoirement adossé à un professionnel de santé référencé dans le carnet d'adresses. Un praticien peut être consulté lors de multiples rendez-vous.</td>
    </tr>
    <tr>
      <td><strong>Practitioner &harr; HealthFacility</strong></td>
      <td>Association dirigée (<code>--&gt;</code>)</td>
      <td><code>0..* &harr; 0..1</code></td>
      <td>Un praticien peut exercer au sein d'un établissement identifié (cabinet, hôpital) ou être sans structure enregistrée (téléconsultation exclusive).</td>
    </tr>
    <tr>
      <td><strong>Appointment &harr; ConsultationRecord</strong></td>
      <td>Composition (<code>*--</code>)</td>
      <td><code>1 &harr; 0..1</code></td>
      <td>Tant que le rendez-vous n'est pas honoré, aucun compte-rendu n'existe (<code>0</code>). Dès que la visite s'achève, un compte-rendu clinique unique (<code>1</code>) peut être rattaché à l'événement d'agenda.</td>
    </tr>
    <tr>
      <td><strong>PlannedIntake / Appointment &harr; NotificationAlert</strong></td>
      <td>Dépendance d'effet (<code>..&gt;</code>)</td>
      <td><code>1 &harr; 0..*</code></td>
      <td>Chaque prise planifiée ou rendez-vous programme ses alarmes locales dédiées (H-2, J-2, heure exacte) via l'ordonnanceur d'alertes.</td>
    </tr>
  </tbody>
</table>
''';
