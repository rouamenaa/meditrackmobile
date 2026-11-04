const String section7MainScenarioHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">7</span> Scénario Principal Complet (Cycle de Vie en 12 Étapes)</h1>
<p>Ce scénario de référence déroule l'intégralité du cycle d'usage nominal de MediTrack. Chacune des douze étapes est documentée selon une grille d'ingénierie stricte détaillant l'ensemble des interactions entre l'interface, les composants métier, les transactions de données et les services matériels.</p>

<!-- ETAPE 1 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 1</span> Initialisation Sécurisée & Démarrage de l'Application</span>
    <span class="badge badge-primary">Cycle de Vie</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient / Utilisateur.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>SplashScreen</code> &rarr; <code>LoginScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">L'application MediTrack est installée sur un terminal Android ou iOS.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>User</code>, <code>UserSession</code>, <code>SecurityLog</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur appuie sur l'icône de l'application MediTrack sur l'écran d'accueil du smartphone.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val">Le <code>main()</code> initialise les liaisons Flutter, instancie le conteneur d'injection de dépendances (GetIt/Riverpod), sollicite <code>FlutterSecureStorage</code> pour vérifier l'existence de la clé de chiffrement maîtresse de la base de données, et réveille l'adaptateur de notifications locales (<code>NotificationScheduler</code>).</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Lecture de la table de configuration système. La base SQLCipher est localisée mais reste verrouillée (chiffrée) tant que les identifiants ou le jeton biométrique n'ont pas été validés.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Aucune notification émise. <em>Fonctionnement dégradé :</em> Si les capteurs biométriques matériels sont absents ou défaillants, le système bascule immédiatement sur l'invite mot de passe/PIN de secours.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">L'écran d'authentification s'affiche instantanément. L'état applicatif est <code>UnauthenticatedState</code>.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 2 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 2</span> Authentification Biométrique & Déverrouillage du Coffre-Fort</span>
    <span class="badge badge-success">Sécurité</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>LoginScreen</code> &rarr; Boîte de dialogue biométrique OS.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Compte utilisateur existant avec option biométrique activée au préalable.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>User</code>, <code>AuthService</code>, <code>SessionManager</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur pose son doigt sur le capteur d'empreinte digitale ou regarde la caméra frontale (Face ID).</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>AuthBloc</code> invoque <code>LocalAuthService.authenticate()</code>. Suite au succès renvoyé par l'enclave sécurisée de l'OS (StrongBox / Secure Enclave), <code>FlutterSecureStorage</code> libère la clé AES-256 de 256 bits. <code>DatabaseHelper</code> applique <code>PRAGMA key = 'raw_key'</code> sur la base SQLite SQLCipher.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Écriture : <code>UPDATE users SET last_login_at = datetime('now'), failed_attempts = 0 WHERE id = ?</code>. Insertion d'une ligne d'audit <code>security_logs (event_type='BIOMETRIC_AUTH', success=1)</code>. Lecture du profil utilisateur complet dans <code>patient_profiles</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Aucune notification. <em>Mode dégradé :</em> En cas d'échec de reconnaissance biométrique (doigt humide), l'utilisateur bascule sur la saisie de son mot de passe ou code PIN à 6 chiffres.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">La session est déclarée active en mémoire (<code>UserSession.activeUser</code> instancié). La base de données est ouverte et déchiffrée.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 3 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 3</span> Accès au Tableau de Bord Central (Dashboard Synthétique)</span>
    <span class="badge badge-primary">Navigation</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>DashboardScreen</code> (Écran d'accueil principal).</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Session utilisateur ouverte et base déchiffrée.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>PlannedIntake</code>, <code>Appointment</code>, <code>PhysicalActivity</code>, <code>AdherenceEngine</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur visualise la synthèse de sa journée : prochaines prises médicamenteuses, statut de l'armoire, jauge d'activité et prochains rendez-vous.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val">Le <code>DashboardBloc</code> émet des requêtes asynchrones parallèles via <code>GetTodayIntakesUseCase</code>, <code>GetUpcomingAppointmentsUseCase</code>, <code>GetWeeklyActivitySummaryUseCase</code> et <code>CalculateAdherenceRateUseCase</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Lectures optimisées : <code>SELECT * FROM planned_intakes WHERE date(scheduled_datetime) = date('now')</code>; <code>SELECT * FROM appointments WHERE date(start_datetime) &gt;= date('now') ORDER BY start_datetime LIMIT 2</code>; <code>SELECT sum(calories_burned) FROM physical_activities WHERE date(start_datetime) &gt;= date('now', '-7 days')</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Vérification passive des alertes silencieuses en attente. Fonctionnement nominal instantané 100% hors-ligne.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">Toutes les cartes réactives du tableau de bord sont chargées et affichent la situation médicale exacte du jour.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 4 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 4</span> Consultation et Mise à Jour du Profil Médical</span>
    <span class="badge badge-neutral">Profil</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>ProfileScreen</code> &rarr; <code>EditProfileScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Accès au profil depuis le menu de navigation inférieur.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>PatientProfile</code>, <code>BiologicalSex</code>, <code>BloodGroup</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur actualise son poids (passage de 78.0 kg à 76.5 kg) et ajoute une allergie médicamenteuse avérée (<em>"Pénicilline"</em>). Il clique sur "Enregistrer les modifications".</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>ProfileBloc</code> valide les bornes numériques (poids &ge; 2kg et &le; 350kg), réévalue dynamiquement l'IMC via <code>PatientProfile.calculateBmi()</code>, et transmet les données au <code>UpdateProfileUseCase</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Écriture : <code>UPDATE patient_profiles SET weight_kg = 76.5, allergies_json = '["Pénicilline"]' WHERE user_id = ?</code>. Audit : <code>INSERT INTO security_logs (event_type='PROFILE_UPDATE', ...)</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Notification visuelle in-app (Toast/SnackBar : "Profil mis à jour"). Les futurs calculs d'activité physique prendront immédiatement en compte la nouvelle valeur pondérale.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">Le profil est synchronisé localement avec le nouvel IMC affiché.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 5 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 5</span> Enregistrement d'une Activité Physique & Calcul Métabolique MET</span>
    <span class="badge badge-success">Activité</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>ActivityTrackerScreen</code> &rarr; <code>AddActivityDialog</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Séance sportive réalisée ou en cours de déclaration.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>PhysicalActivity</code>, <code>MetabolicCalculator</code>, <code>ActivityGoal</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur sélectionne <em>"Marche"</em>, durée : <em>45 minutes</em>, intensité : <em>"Modérée"</em>. Il laisse le champ distance vide et valide.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>ActivityBloc</code> interroge <code>MetabolicCalculator</code>. Ce dernier identifie la valeur MET de la marche modérée (3.8 MET) et calcule : $\text{Calories} = 3.8 \times 76.5 \times (45/60) = 218.0 \text{ kcal}$. La distance est inférée : $4.8 \text{ km/h} \times 0.75 \text{ h} = 3.6 \text{ km}$.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Écriture : <code>INSERT INTO physical_activities (user_id, activity_type, duration_minutes, distance_km, intensity, calories_burned, data_source) VALUES (?, 'WALKING', 45, 3.6, 'MODERATE', 218.0, 'CALCULATED_INTERNAL')</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Message d'encouragement affiché si l'objectif hebdomadaire OMS (150 min) progresse. <em>Mode dégradé :</em> En l'absence de capteurs GPS ou podomètre, la saisie purement manuelle est entièrement fonctionnelle.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">L'activité apparaît dans l'historique et l'anneau d'effort hebdomadaire se remplit de +45 minutes.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 6 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 6</span> Enregistrement de Médicaments dans l'Armoire à Pharmacie</span>
    <span class="badge badge-warning">Inventaire</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>MedicationInventoryScreen</code> &rarr; <code>AddMedicationScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Acquisition physique d'une boîte de médicaments en pharmacie.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>Medication</code>, <code>StockMovement</code>, <code>GalenicForm</code>, <code>AdministrationRoute</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur saisit : Nom : <em>"Kardegic"</em>, DCI : <em>"Acide acétylsalicylique"</em>, Dosage : <em>75 mg</em>, Forme : <em>Poudre orale en sachet</em>, Quantité : <em>30 sachets</em>, Seuil alerte : <em>5 sachets</em>, Péremption : <em>30/06/2027</em>. Il valide l'ajout.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>MedicationBloc</code> appelle <code>AddMedicationUseCase</code> qui vérifie l'invariance métier (stock initial &ge; 0, date péremption future). Le service d'alerte enregistre un trigger d'alerte de péremption à J-30 (31/05/2027).</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Transaction SQLite : <code>INSERT INTO medications (...) VALUES (...)</code> suivie de <code>INSERT INTO stock_movements (movement_type='INITIAL_INVENTORY', quantity_change=30, stock_after=30, ...)</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Programmation locale de la notification d'alerte de péremption. Aucune connexion externe requise.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">Le médicament est répertorié dans l'inventaire avec un badge vert « Stock Confortable (30 sachets) ».</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 7 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 7</span> Création d'un Traitement & Configuration du Planning de Prises</span>
    <span class="badge badge-primary">Prescription</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>TreatmentListScreen</code> &rarr; <code>NewTreatmentWizardScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Le médicament "Kardegic 75mg" est disponible dans l'inventaire.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>Treatment</code>, <code>PrescriptionItem</code>, <code>IntakeSchedule</code>, <code>PlannedIntake</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur crée le traitement <em>"Prévention Cardiovasculaire"</em>, prescrit par le <em>Dr. Morel</em>. Il associe <em>"Kardegic 75mg"</em>, dose : <em>1 sachet</em>, fréquence : <em>Quotidienne à 08:00</em>, condition : <em>Au milieu du repas</em>, traitement chronique (sans date de fin).</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>ScheduleTreatmentUseCase</code> valide la cohérence de l'horaire. Il invoque l'ordonnanceur prédictif qui génère 14 instances <code>PlannedIntake</code> (pour les 14 prochains jours à 08:00) et fait appel à <code>NotificationScheduler.scheduleExactAlarm()</code> pour programmer les réveils du terminal.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Écritures dans <code>treatments</code>, <code>prescription_items</code>, <code>intake_schedules</code> et insertions en lot de 14 lignes dans <code>planned_intakes (status='SCHEDULED')</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">14 alarmes matérielles exactes enregistrées dans le système de notification local de l'OS.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">Le traitement est actif. Le calendrier des prises prévisionnelles est peuplé et visible dans l'agenda.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 8 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 8</span> Réception de Rappel & Enregistrement d'une Prise Effective</span>
    <span class="badge badge-success">Observance</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Système OS (déclencheur) & Patient (acteur).</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val">Notification Système Push &rarr; <code>DashboardScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Il est 08:00 du matin. Une <code>PlannedIntake</code> est à l'état <code>SCHEDULED</code>.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>PlannedIntake</code>, <code>IntakeLog</code>, <code>Medication</code>, <code>StockMovement</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'alarme retentit à 08:00. Le patient prend son sachet de Kardegic avec un verre d'eau et appuie sur le bouton <strong>[Prendre]</strong> de la notification interactive.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val">Le récepteur d'événements d'arrière-plan de <code>flutter_local_notifications</code> transmet l'ordre à <code>RecordMedicationIntakeUseCase</code>. Le use case exécute la transaction d'enregistrement de prise et décrémente l'armoire à pharmacie.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Transaction ACID : <code>UPDATE planned_intakes SET status = 'TAKEN' WHERE id = ?</code>; <code>INSERT INTO intake_logs (actual_taken_datetime, actual_dose, status='TAKEN_ON_TIME', is_within_tolerance=1)</code>; <code>UPDATE medications SET current_stock = current_stock - 1 WHERE id = ?</code> (solde = 29); <code>INSERT INTO stock_movements (movement_type='TREATMENT_CONSUMPTION', quantity_change=-1, stock_after=29)</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">L'alarme de 08:00 est immédiatement acquittée et fermée. Le stock restant étant de 29 (&gt; seuil critique de 5), aucune alerte de rupture n'est déclenchée.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">La prise est archivée avec succès. L'observance thérapeutique du patient est calculée à 100% sur cette séquence.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 9 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 9</span> Planification d'un Rendez-vous Médical Spécialisé</span>
    <span class="badge badge-primary">Soins</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>AppointmentListScreen</code> &rarr; <code>AddAppointmentScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Praticien référencé ou nouveau praticien créé.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>Appointment</code>, <code>Practitioner</code>, <code>HealthFacility</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur planifie une consultation : Praticien : <em>"Dr. Morel (Cardiologue)"</em>, Lieu : <em>"Clinique du Parc, Bâtiment B"</em>, Date : <em>15 Novembre à 14h30</em>, Motif : <em>"Contrôle semestriel tension"</em>. Il active les rappels et clique sur "Confirmer".</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>AppointmentBloc</code> fait appel à <code>ScheduleAppointmentUseCase</code>. Le service calcule les dates de déclenchement des rappels : J-2 (13 Novembre à 14h30) et H-2 (15 Novembre à 12h30), et les enregistre auprès du planificateur d'alarmes.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Écriture : <code>INSERT INTO appointments (user_id, practitioner_id, health_facility_id, start_datetime, duration_minutes, purpose, modality, status) VALUES (?, ?, ?, '2026-11-15T14:30:00Z', 30, 'Contrôle semestriel tension', 'IN_PERSON', 'SCHEDULED')</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Deux alarmes exactes programmées dans le gestionnaire système.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">Le rendez-vous apparaît dans la chronologie de l'agenda avec le compte à rebours des jours restants.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 10 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 10</span> Réception du Rappel Préalable Avant la Consultation</span>
    <span class="badge badge-warning">Rappel</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Système OS (déclencheur) & Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val">Notification Système Push &rarr; <code>AppointmentDetailScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Date : 13 Novembre à 14h30 (exactement 48h avant le rendez-vous).</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>Appointment</code>, <code>NotificationAlert</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">Le patient reçoit la notification : <em>"MediTrack : Consultation Dr. Morel dans 48h. Pensez à apporter vos derniers résultats d'analyses sanguines."</em> Il clique sur la notification pour vérifier l'adresse.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val">L'alarme déclenche <code>NotificationBroadcastReceiver</code> qui positionne l'indicateur de rappel 48h à vrai via <code>AppointmentRepository.markReminderSent(apptId, '48h')</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Écriture : <code>UPDATE appointments SET reminder_48h_sent = 1 WHERE id = ?</code>. Lecture des coordonnées géographiques de <code>health_facilities</code> pour générer le lien de cartographie.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Notification délivrée au centre de notifications. Le bouton "Voir itinéraire" ouvre l'application cartographique native (Google Maps / Apple Plans).</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">Le patient est informé et prépare ses documents cliniques deux jours à l'avance.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 11 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 11</span> Consultation de l'Historique Global et du Bilan d'Observance</span>
    <span class="badge badge-success">Analytique</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>AdherenceReportScreen</code> & <code>HistoryTimelineScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Plusieurs jours d'historique de prises et d'activités enregistrés.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>AdherenceEngine</code>, <code>IntakeLog</code>, <code>PhysicalActivity</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur consulte le rapport mensuel d'observance pour le présenter à son médecin. Il visualise le calendrier coloré (vert pour les prises régulières, orange pour les reports) et le cumul d'activité physique.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>AdherenceBloc</code> sollicite <code>AdherenceEngine.calculateAdherenceRate()</code> qui analyse l'ensemble des <code>planned_intakes</code> échues et des <code>intake_logs</code> correspondants sur les 30 derniers jours.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Requête d'agrégation SQL : jointure entre <code>planned_intakes</code> et <code>intake_logs</code>, filtrée sur la plage temporelle. Lecture des cumuls de minutes d'activité dans <code>physical_activities</code>.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Génération optionnelle d'un récapitulatif PDF médical imprimable pour la consultation. 100% exécuté hors-ligne sur le terminal.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">Le patient visualise son score (ex: 94% - Statut "Optimale") et dispose d'une preuve clinique tangible pour son praticien.</span>
      </div>
    </div>
  </div>
</div>

<!-- ETAPE 12 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Étape 12</span> Déconnexion Sécurisée & Verrouillage Cryptographique</span>
    <span class="badge badge-danger">Clôture</span>
  </div>
  <div class="step-body">
    <div class="step-grid">
      <div><span class="step-field-label">Acteur :</span> <span class="step-field-val">Patient.</span></div>
      <div><span class="step-field-label">Écran :</span> <span class="step-field-val"><code>SettingsScreen</code> &rarr; <code>LoginScreen</code>.</span></div>
      <div><span class="step-field-label">Préconditions :</span> <span class="step-field-val">Session utilisateur en cours.</span></div>
      <div><span class="step-field-label">Classes Métier :</span> <span class="step-field-val"><code>UserSession</code>, <code>SecurityLog</code>, <code>AuthService</code>.</span></div>
      <div class="step-full-row">
        <span class="step-field-label">Action Utilisateur :</span>
        <span class="step-field-val">L'utilisateur clique sur le bouton "Se déconnecter" dans l'onglet des paramètres de sécurité.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Appels entre Services :</span>
        <span class="step-field-val"><code>AuthBloc</code> ordonne la fermeture de session à <code>SessionManager.logout()</code>. La clé AES-256 en mémoire vive est écrasée (zeroing cryptographique), la connexion SQLite SQLCipher est fermée proprement (<code>db.close()</code>), et le cache mémoire des widgets est purgé.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Lectures / Écritures BDD :</span>
        <span class="step-field-val">Dernière écriture avant verrouillage : <code>INSERT INTO security_logs (user_id, event_type='LOGOUT', timestamp=datetime('now'), success=1)</code>. Fermeture du canal de persistance.</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Notifications & Dégradé :</span>
        <span class="step-field-val">Les alarmes système préprogrammées restent actives au niveau de l'OS (les réveils auront lieu même déconnecté, mais exigeront une ré-authentification pour accéder aux détails).</span>
      </div>
      <div class="step-full-row">
        <span class="step-field-label">Résultat & Postconditions :</span>
        <span class="step-field-val">L'application retourne sur l'écran d'authentification initial. Aucune donnée médicale n'est plus accessible sans nouvelle authentification.</span>
      </div>
    </div>
  </div>
</div>
''';
