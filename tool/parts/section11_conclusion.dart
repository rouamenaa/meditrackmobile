const String section11ConclusionHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">11</span> Conclusion Récapitulative & Matrice de Traçabilité</h1>

<h2>11.1 Synthèse de la Conception Cible</h2>
<p>La présente spécification d'ingénierie logicielle pour <strong>MediTrack</strong> pose les fondations d'un système de santé mobile rigoureux, pérenne et centré sur le patient. En s'affranchissant des limitations partielles de l'implémentation initiale, ce document livre une modélisation exhaustive structurée autour de cinq modules fondamentaux en parfaite synergie :</p>
<ul>
  <li>Un <strong>Module Utilisateur & Profil</strong> étanche, sécurisé par cryptographie de pointe (Argon2id, biométrie, SQLCipher AES-256) et pourvu d'un dossier clinique d'urgence.</li>
  <li>Un <strong>Module Activité Physique</strong> adossé au modèle biomécanique international MET, valorisant l'hygiène de vie sans jamais empiéter sur le diagnostic médical.</li>
  <li>Un <strong>Module Médicaments</strong> distinguant formellement l'armoire à pharmacie matérielle, ses formes galéniques, ses seuils critiques et la traçabilité de ses péremptions.</li>
  <li>Un <strong>Module Traitements & Observance</strong> tripartite (Traitement &rarr; Prescription &rarr; Prise prévisionnelle), garantissant une gestion chirurgicale des posologies, la décrémentation atomique des stocks et le calcul scientifiquement éprouvé de l'adhérence thérapeutique.</li>
  <li>Un <strong>Module Rendez-vous</strong> coordonnant le carnet d'adresses soignant, les alarmes préalables multi-échéances (J-2, H-2) et la mémoire clinique des consultations réalisées.</li>
</ul>

<h2>11.2 Matrice de Traçabilité des Exigences Métier</h2>
<p>Le tableau ci-dessous atteste de la couverture exhaustive de l'ensemble des exigences du cahier des charges au travers des artefacts de modélisation produits :</p>

<table>
  <thead>
    <tr>
      <th style="width: 25%;">Exigence Métier du Périmètre</th>
      <th style="width: 25%;">Entités Métier & Value Objects</th>
      <th style="width: 25%;">Tables BDD Relationnelles</th>
      <th style="width: 25%;">Diagrammes UML & Scénarios</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Module 1 : Auth, Profil & Sécurité</strong><br>Inscription, biométrie, sessions, profil patient, préférences, mode discret, audit.</td>
      <td><code>User</code>, <code>PatientProfile</code>, <code>UserPreferences</code>, <code>SecurityLog</code>, <code>AuthService</code>.</td>
      <td><code>users</code>, <code>patient_profiles</code>, <code>user_preferences</code>, <code>security_logs</code>.</td>
      <td>Figures 3.1, 4.1, 6.1, 6.2 (Séquence Auth). Scénarios Étape 1, 2, 4, 12, A.1, A.2.</td>
    </tr>
    <tr>
      <td><strong>Module 2 : Activité Physique</strong><br>CRUD séances, typologie, MET, calories, vitesse, objectifs hebdo OMS, filtres.</td>
      <td><code>PhysicalActivity</code>, <code>ActivityGoal</code>, <code>MetabolicCalculator</code>, <code>ActivityType</code>.</td>
      <td><code>physical_activities</code>, <code>activity_goals</code>.</td>
      <td>Figures 3.1, 4.2, 6.1, 6.6 (Activité). Scénarios Étape 5, A.4.</td>
    </tr>
    <tr>
      <td><strong>Module 3 : Médicaments</strong><br>Inventaire armoire, DCI, formes galéniques, voies d'administration, stocks, péremptions J-30/J-7/J-0.</td>
      <td><code>Medication</code>, <code>StockMovement</code>, <code>GalenicForm</code>, <code>Dosage</code>, <code>AdministrationRoute</code>.</td>
      <td><code>medications</code>, <code>stock_movements</code>.</td>
      <td>Figures 3.1, 4.3, 6.1, 6.4 (Séquence Prise). Scénarios Étape 6, A.5, A.6.</td>
    </tr>
    <tr>
      <td><strong>Module 4 : Traitements & Prises</strong><br>Pathologies, prescriptions, planning récurrent, prises prévues, logs d'ingestion, taux d'observance OMS.</td>
      <td><code>Treatment</code>, <code>PrescriptionItem</code>, <code>IntakeSchedule</code>, <code>PlannedIntake</code>, <code>IntakeLog</code>, <code>AdherenceEngine</code>.</td>
      <td><code>treatments</code>, <code>prescription_items</code>, <code>intake_schedules</code>, <code>planned_intakes</code>, <code>intake_logs</code>.</td>
      <td>Figures 3.1, 4.4, 6.1, 6.3, 6.4, 6.7, 6.8. Scénarios Étape 7, 8, 11, A.7, A.8.</td>
    </tr>
    <tr>
      <td><strong>Module 5 : Rendez-vous Médicaux</strong><br>Praticiens, établissements, GPS, motifs, statuts, rappels J-2 et H-2, comptes-rendus et constantes.</td>
      <td><code>Appointment</code>, <code>Practitioner</code>, <code>HealthFacility</code>, <code>ConsultationRecord</code>, <code>AppointmentStatus</code>.</td>
      <td><code>practitioners</code>, <code>health_facilities</code>, <code>appointments</code>, <code>consultation_records</code>.</td>
      <td>Figures 3.1, 4.5, 6.1, 6.5, 6.9. Scénarios Étape 9, 10, A.9.</td>
    </tr>
    <tr>
      <td><strong>Exigences Techniques & Non-Fonctionnelles</strong><br>Offline-First, SQLCipher AES-256, Secure Storage, AlarmClock exact, Clean Architecture, BLoC.</td>
      <td><code>IUserRepository</code>, <code>ITreatmentRepository</code>, <code>INotificationScheduler</code>, <code>Failure/Result</code>.</td>
      <td>Intégrité 3NF, contraintes CHECK, clés étrangères, index B-Tree, Soft Delete.</td>
      <td>Figures 4.6 (Services), 5.1 (ERD), 6.10 (Composants). Scénarios Étape 12, A.10, A.11.</td>
    </tr>
  </tbody>
</table>

<h2>11.3 Recommandations Stratégiques pour le Développement</h2>
<p>Pour assurer le succès de la mise en œuvre de cette conception cible dans le codebase Flutter :</p>
<ol>
  <li><strong>Prioriser la Couche Domaine :</strong> Implémenter en premier lieu les entités pures Dart, les Value Objects immuables et les Use Cases avec une couverture de tests unitaires supérieure à 90%. La logique médicale (calcul MET, calcul d'observance, génération d'horizon de prises) doit être infaillible avant tout raccordement à l'interface graphique.</li>
  <li><strong>Valider le Chiffrement SQLCipher dès le Démarrage :</strong> Mettre en place la persistance locale chiffrée avec le plugin <code>sqflite_sqlcipher</code> et tester l'ouverture de la base avec la clé maîtresse stockée dans <code>flutter_secure_storage</code> sur un ensemble varié d'émulateurs et d'appareils physiques Android et iOS.</li>
  <li><strong>Éprouver les Réveils Matériels sur Écrans Éteints :</strong> Valider le comportement de <code>flutter_local_notifications</code> sur des terminaux Android avec écran éteint depuis plus de 60 minutes afin de s'assurer que l'API <code>setExactAndAllowWhileIdle()</code> franchit les barrières du mode Doze.</li>
  <li><strong>Intégration Continue et Rigueur UML :</strong> Tout écart futur par rapport au présent modèle de classes ou au schéma de base de données doit faire l'objet d'une révision d'architecture formelle pour préserver la cohérence systémique de MediTrack.</li>
</ol>
''';
