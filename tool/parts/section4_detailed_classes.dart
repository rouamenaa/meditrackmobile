const String section4DetailedClassesHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">4</span> Diagrammes Détaillés par Module & Architecture Technique</h1>
<p>Pour assurer une parfaite lisibilité sans compromis sur l'exhaustivité des signatures d'attributs et de méthodes, cette section décompose l'architecture de MediTrack en six diagrammes modulaires spécialisés.</p>

<h2>4.1 Module 1 Détaillé : Authentification, Profil & Sécurité</h2>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 4.1 — Diagramme de Classes Spécifique au Module 1</span>
    <span class="diagram-type">UML Class Diagram</span>
  </div>
  <div class="mermaid">
classDiagram
    direction TB

    class User {
        -UUID id
        -String email
        -String passwordHash
        -String salt
        -String pinHash
        -Boolean isBiometricEnabled
        -int failedAttemptsCount
        -DateTime lockUntil
        -DateTime createdAt
        -DateTime lastLoginAt
        +authenticate(String password) Boolean
        +verifyPin(String pin) Boolean
        +changePassword(String oldPwd, String newPwd) Boolean
        +setPin(String pin)
        +enableBiometrics(Boolean enable)
        +recordFailedAttempt()
        +resetFailedAttempts()
        +isLocked() Boolean
    }

    class PatientProfile {
        -UUID id
        -UUID userId
        -String firstName
        -String lastName
        -DateTime birthDate
        -BiologicalSex sex
        -Double heightCm
        -Double weightKg
        -BloodGroup bloodGroup
        -List~String~ allergies
        -List~String~ medicalHistory
        -String emergencyContactName
        -String emergencyContactPhone
        -String emergencyContactRelation
        +calculateBmi() Double
        +getBmiCategory() String
        +getAge() int
        +updateBiometrics(Double height, Double weight)
        +addAllergy(String allergen)
        +removeAllergy(String allergen)
    }

    class UserPreferences {
        -UUID id
        -UUID userId
        -Boolean isDiscreteMode
        -Boolean enableSound
        -Boolean enableVibration
        -String quietHoursStart
        -String quietHoursEnd
        -int appointmentReminderHoursDefault
        -Boolean allowCriticalAlertsDuringQuiet
        +toggleDiscreteMode()
        +setQuietHours(String start, String end)
        +isQuietTimeNow() Boolean
    }

    class SecurityLog {
        -UUID id
        -UUID userId
        -SecurityEventType eventType
        -DateTime timestamp
        -String ipAddressOrDevice
        -Boolean success
        -String details
    }

    class BiologicalSex {
        <<enumeration>>
        MALE
        FEMALE
        OTHER
    }

    class BloodGroup {
        <<enumeration>>
        A_POSITIVE
        A_NEGATIVE
        B_POSITIVE
        B_NEGATIVE
        AB_POSITIVE
        AB_NEGATIVE
        O_POSITIVE
        O_NEGATIVE
    }

    class SecurityEventType {
        <<enumeration>>
        LOGIN_ATTEMPT
        BIOMETRIC_AUTH
        PASSWORD_CHANGE
        PIN_CHANGE
        ACCOUNT_LOCKOUT
        PROFILE_UPDATE
    }

    User "1" *-- "1" PatientProfile : possède
    User "1" *-- "1" UserPreferences : configure
    User "1" *-- "0..*" SecurityLog : enregistre
    PatientProfile ..> BiologicalSex
    PatientProfile ..> BloodGroup
    SecurityLog ..> SecurityEventType
  </div>
  <div class="diagram-caption">Figure 4.1 — Modélisation des entités d'authentification, du profil clinique et de la sécurité locale.</div>
</div>

<div class="page-break"></div>

<h2>4.2 Module 2 Détaillé : Activité Physique & Métriques Métaboliques</h2>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 4.2 — Diagramme de Classes Spécifique au Module 2</span>
    <span class="diagram-type">UML Class Diagram</span>
  </div>
  <div class="mermaid">
classDiagram
    direction TB

    class PhysicalActivity {
        -UUID id
        -UUID userId
        -ActivityType activityType
        -DateTime startDateTime
        -int durationMinutes
        -Double distanceKm
        -ActivityIntensity intensity
        -int rpeScore
        -Double caloriesBurned
        -int avgHeartRateBpm
        -int maxHeartRateBpm
        -String notes
        -DataSource source
        +calculateEstimatedCalories(Double weightKg) Double
        +getPaceMinPerKm() Double
        +getSpeedKmH() Double
    }

    class ActivityGoal {
        -UUID id
        -UUID userId
        -GoalFrequency frequency
        -int targetDurationMinutes
        -Double targetCalories
        -int targetSteps
        -DateTime startDate
        -DateTime endDate
        -Boolean isActive
        +calculateProgress(int currentMinutes) Double
        +isAchieved(int currentMinutes) Boolean
    }

    class MetabolicCalculator {
        <<utility / domain service>>
        +getMetValue(ActivityType type, ActivityIntensity intensity) Double
        +calculateCalories(Double met, Double weightKg, int durationMinutes) Double
        +calculateBmrMifflin(Double weightKg, Double heightCm, int age, BiologicalSex sex) Double
    }

    class ActivityType {
        <<enumeration>>
        WALKING
        RUNNING
        CYCLING
        SWIMMING
        FITNESS_STRENGTH
        YOGA_PILATES
        GENTLE_GYM
        OTHER
    }

    class ActivityIntensity {
        <<enumeration>>
        LIGHT
        MODERATE
        VIGOROUS
    }

    class DataSource {
        <<enumeration>>
        MANUAL_DECLARATIVE
        CALCULATED_INTERNAL
        EXTERNAL_SENSOR_SYNC
    }

    class GoalFrequency {
        <<enumeration>>
        DAILY
        WEEKLY
    }

    PhysicalActivity ..> ActivityType
    PhysicalActivity ..> ActivityIntensity
    PhysicalActivity ..> DataSource
    PhysicalActivity ..> MetabolicCalculator : utilise
    ActivityGoal ..> GoalFrequency
  </div>
  <div class="diagram-caption">Figure 4.2 — Modélisation du suivi de l'effort physique et du moteur de calcul métabolique MET.</div>
</div>

<div class="page-break"></div>

<h2>4.3 Module 3 Détaillé : Médicaments, Galénique & Inventaire</h2>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 4.3 — Diagramme de Classes Spécifique au Module 3</span>
    <span class="diagram-type">UML Class Diagram</span>
  </div>
  <div class="mermaid">
classDiagram
    direction TB

    class Medication {
        -UUID id
        -UUID userId
        -String commercialName
        -String genericNameDci
        -String regulatoryCodeCis
        -Double dosageValue
        -String dosageUnit
        -GalenicForm form
        -AdministrationRoute route
        -Double currentStock
        -Double minStockThreshold
        -DateTime expiryDate
        -String batchNumber
        -DateTime createdAt
        +isLowStock() Boolean
        +isExpired() Boolean
        +daysUntilExpiry() int
        +getExpiryAlertLevel() ExpiryAlertLevel
        +decrementStock(Double quantity, String reason) StockMovement
        +restock(Double quantity, DateTime newExpiryDate, String batch) StockMovement
    }

    class StockMovement {
        -UUID id
        -UUID medicationId
        -MovementType movementType
        -Double quantityChange
        -Double stockAfter
        -DateTime movementDate
        -String reason
    }

    class GalenicForm {
        <<enumeration>>
        TABLET
        CAPSULE
        ORAL_SOLUTION
        SYRUP
        POWDER_SACHET
        CREAM_OINTMENT
        GEL
        EYE_DROPS
        EAR_DROPS
        INHALER_SPRAY
        INJECTABLE
        TRANSDERMAL_PATCH
        SUPPOSITORY
    }

    class AdministrationRoute {
        <<enumeration>>
        ORAL
        SUBLINGUAL
        CUTANEOUS
        INHALED
        OCULAR
        AURICULAR
        NASAL
        INTRAVENOUS
        SUBCUTANEOUS
        RECTAL
    }

    class MovementType {
        <<enumeration>>
        INITIAL_INVENTORY
        RESTOCK_PURCHASE
        TREATMENT_CONSUMPTION
        MANUAL_ADJUSTMENT
        DISCARDED_EXPIRED
    }

    class ExpiryAlertLevel {
        <<enumeration>>
        VALID
        EXPIRING_30_DAYS
        EXPIRING_7_DAYS
        EXPIRED
    }

    Medication "1" *-- "0..*" StockMovement : trace
    Medication ..> GalenicForm
    Medication ..> AdministrationRoute
    Medication ..> ExpiryAlertLevel
    StockMovement ..> MovementType
  </div>
  <div class="diagram-caption">Figure 4.3 — Modélisation de l'armoire à pharmacie, des formes galéniques et du journal d'audit de stock.</div>
</div>

<div class="page-break"></div>

<h2>4.4 Module 4 Détaillé : Traitements, Planning & Observance</h2>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 4.4 — Diagramme de Classes Spécifique au Module 4</span>
    <span class="diagram-type">UML Class Diagram</span>
  </div>
  <div class="mermaid">
classDiagram
    direction TB

    class Treatment {
        -UUID id
        -UUID userId
        -String title
        -String pathology
        -String prescribingDoctor
        -DateTime startDate
        -DateTime endDate
        -Boolean isChronic
        -TreatmentStatus status
        -String generalInstructions
        +pauseTreatment()
        +resumeTreatment()
        +completeTreatment()
        +cancelTreatment(String reason)
        +isActive() Boolean
    }

    class PrescriptionItem {
        -UUID id
        -UUID treatmentId
        -UUID medicationId
        -Double unitDose
        -String unitLabel
        -MealCondition mealCondition
        -String instructions
        -Boolean isPrn
        -int maxDailyDosesPrn
    }

    class IntakeSchedule {
        -UUID id
        -UUID prescriptionItemId
        -ScheduleType scheduleType
        -List~String~ targetTimes
        -List~int~ daysOfWeek
        -int intervalHours
        +generatePlannedIntakes(DateTime from, DateTime to) List~PlannedIntake~
    }

    class PlannedIntake {
        -UUID id
        -UUID intakeScheduleId
        -DateTime scheduledDateTime
        -Double doseToTake
        -int toleranceMinutes
        -IntakeStatus status
        +markAsTaken(Double actualDose) IntakeLog
        +markAsMissed()
        +snooze(int minutes)
        +isOverdue() Boolean
    }

    class IntakeLog {
        -UUID id
        -UUID plannedIntakeId
        -DateTime actualTakenDateTime
        -Double actualDose
        -IntakeLogStatus status
        -String notes
        -Boolean isWithinTolerance
    }

    class AdherenceEngine {
        <<domain service>>
        +calculateAdherenceRate(List~PlannedIntake~ intakes, List~IntakeLog~ logs) Double
        +getAdherenceLevel(Double rate) AdherenceLevel
    }

    class TreatmentStatus {
        <<enumeration>>
        ACTIVE
        PAUSED
        COMPLETED
        CANCELLED
    }

    class IntakeStatus {
        <<enumeration>>
        SCHEDULED
        NOTIFIED
        TAKEN
        MISSED
        SNOOZED
        SKIPPED
    }

    class MealCondition {
        <<enumeration>>
        FASTING
        BEFORE_MEAL
        DURING_MEAL
        AFTER_MEAL
        BEDTIME
        INDIFFERENT
    }

    class ScheduleType {
        <<enumeration>>
        DAILY
        CYCLIC
        WEEKLY_DAYS
        HOURLY_INTERVAL
        AS_NEEDED_PRN
    }

    class AdherenceLevel {
        <<enumeration>>
        OPTIMAL_GE_90
        GOOD_80_89
        MODERATE_70_79
        CRITICAL_LT_70
    }

    Treatment "1" *-- "1..*" PrescriptionItem : comprend
    PrescriptionItem "1" *-- "1..*" IntakeSchedule : régit
    IntakeSchedule "1" o-- "0..*" PlannedIntake : produit
    PlannedIntake "1" <-- "0..1" IntakeLog : consigne
    Treatment ..> TreatmentStatus
    PrescriptionItem ..> MealCondition
    IntakeSchedule ..> ScheduleType
    PlannedIntake ..> IntakeStatus
    AdherenceEngine ..> AdherenceLevel
  </div>
  <div class="diagram-caption">Figure 4.4 — Architecture tripartite Traitement / Prescription / Prise effective et moteur d'observance.</div>
</div>

<div class="page-break"></div>

<h2>4.5 Module 5 Détaillé : Rendez-vous Médicaux & Consultations</h2>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 4.5 — Diagramme de Classes Spécifique au Module 5</span>
    <span class="diagram-type">UML Class Diagram</span>
  </div>
  <div class="mermaid">
classDiagram
    direction TB

    class Practitioner {
        -UUID id
        -UUID userId
        -String title
        -String firstName
        -String lastName
        -String specialty
        -String rppsNumber
        -String phone
        -String email
        +getFullName() String
    }

    class HealthFacility {
        -UUID id
        -String facilityName
        -String address
        -String buildingFloor
        -Double latitude
        -Double longitude
        -String phone
    }

    class Appointment {
        -UUID id
        -UUID userId
        -UUID practitionerId
        -UUID healthFacilityId
        -DateTime startDateTime
        -int durationMinutes
        -String purpose
        -AppointmentModality modality
        -String teleconsultUrl
        -AppointmentStatus status
        -Boolean reminder48hSent
        -Boolean reminder2hSent
        +confirm()
        +cancel(String reason)
        +reschedule(DateTime newDate)
        +markCompleted()
        +isPast() Boolean
    }

    class ConsultationRecord {
        -UUID id
        -UUID appointmentId
        -DateTime actualDate
        -String clinicalSummary
        -String doctorAdvice
        -Double systolicBp
        -Double diastolicBp
        -Double recordedWeightKg
        -int restingHeartRateBpm
        -String prescribedExamNotes
        +hasBloodPressureAlert() Boolean
    }

    class AppointmentStatus {
        <<enumeration>>
        SCHEDULED
        CONFIRMED
        RESCHEDULED
        CANCELLED_BY_PATIENT
        CANCELLED_BY_PRACTITIONER
        COMPLETED
        MISSED
    }

    class AppointmentModality {
        <<enumeration>>
        IN_PERSON
        TELECONSULTATION
    }

    Appointment "0..*" --> "1" Practitioner : consulte
    Practitioner "0..*" --> "0..1" HealthFacility : exerce dans
    Appointment "0..*" --> "0..1" HealthFacility : a lieu à
    Appointment "1" *-- "0..1" ConsultationRecord : produit
    Appointment ..> AppointmentStatus
    Appointment ..> AppointmentModality
  </div>
  <div class="diagram-caption">Figure 4.5 — Modélisation du parcours de consultation médicale, des praticiens et des comptes-rendus cliniques.</div>
</div>

<div class="page-break"></div>

<h2>4.6 Architecture Technique : Repositories, Services Applicatifs & Use Cases</h2>
<div class="diagram-container">
  <div class="diagram-header">
    <span class="diagram-title">Figure 4.6 — Diagramme des Interfaces de Données et Services Applicatifs (Clean Architecture)</span>
    <span class="diagram-type">UML Class Diagram</span>
  </div>
  <div class="mermaid">
classDiagram
    direction TB

    %% INTERFACES REPOSITORIES (DOMAIN)
    class IUserRepository {
        <<interface>>
        +getById(UUID id) Future~User~
        +getByEmail(String email) Future~User~
        +save(User user) Future~void~
        +update(User user) Future~void~
    }

    class IMedicationRepository {
        <<interface>>
        +getAll(UUID userId) Future~List~Medication~~
        +getById(UUID id) Future~Medication~
        +save(Medication med) Future~void~
        +decrementStock(UUID id, Double amount) Future~void~
        +getExpiringSoon(UUID userId, int days) Future~List~Medication~~
        +getLowStock(UUID userId) Future~List~Medication~~
    }

    class ITreatmentRepository {
        <<interface>>
        +getActiveTreatments(UUID userId) Future~List~Treatment~~
        +getPlannedIntakes(UUID userId, DateTime day) Future~List~PlannedIntake~~
        +savePlannedIntake(PlannedIntake intake) Future~void~
        +saveIntakeLog(IntakeLog log) Future~void~
        +recordIntakeTransaction(PlannedIntake intake, IntakeLog log, UUID medId, Double dose) Future~void~
    }

    class IAppointmentRepository {
        <<interface>>
        +getUpcoming(UUID userId) Future~List~Appointment~~
        +save(Appointment appt) Future~void~
        +saveConsultationRecord(ConsultationRecord record) Future~void~
    }

    %% USE CASES / INTERACTORS
    class RecordMedicationIntakeUseCase {
        -ITreatmentRepository treatmentRepo
        -IMedicationRepository medicationRepo
        -INotificationScheduler notificationScheduler
        +execute(UUID plannedIntakeId, Double actualDose, String notes) Future~Result~void~~
    }

    class CalculateWeeklyActivityUseCase {
        -IActivityRepository activityRepo
        -IUserRepository userRepo
        +execute(UUID userId) Future~ActivityProgressDto~
    }

    class ScheduleTreatmentIntakesUseCase {
        -ITreatmentRepository treatmentRepo
        -INotificationScheduler notificationScheduler
        +execute(Treatment treatment, List~PrescriptionItem~ items) Future~void~
    }

    %% PLATFORM SERVICES
    class INotificationScheduler {
        <<interface>>
        +scheduleExactAlarm(UUID targetId, DateTime triggerTime, String title, String body) Future~void~
        +cancelAlarm(UUID targetId) Future~void~
        +rescheduleAll(UUID userId) Future~void~
    }

    RecordMedicationIntakeUseCase ..> ITreatmentRepository : utilise
    RecordMedicationIntakeUseCase ..> IMedicationRepository : utilise
    RecordMedicationIntakeUseCase ..> INotificationScheduler : utilise
    ScheduleTreatmentIntakesUseCase ..> ITreatmentRepository : utilise
    ScheduleTreatmentIntakesUseCase ..> INotificationScheduler : utilise
  </div>
  <div class="diagram-caption">Figure 4.6 — Découplage strict entre la logique métier (Use Cases), les contrats de persistance et les sous-systèmes matériels.</div>
</div>
''';
