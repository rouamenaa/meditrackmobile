const String section8AlternativeScenariosHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">8</span> Scénarios Alternatifs et Gestion des Erreurs</h1>
<p>L'ingénierie d'une application de santé critique impose d'anticiper les défaillances, les conflits de données et les comportements imprévus des utilisateurs ou du système d'exploitation. Cette section détaille les onze scénarios d'exception fondamentaux de MediTrack.</p>

<!-- SCENARIO 8.1 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.1</span> Inscription avec une Adresse E-mail Déjà Utilisée</span>
    <span class="badge badge-danger">Conflit Unicité</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> Un utilisateur tente de créer un compte avec une adresse e-mail déjà enregistrée dans la base locale (ex: suite à une réinstallation de l'application ou par un proche sur le même appareil partagé).</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>La tentative d'insertion déclenche une violation de contrainte d'intégrité SQL : <code>UNIQUE constraint failed: users.email</code>.</li>
      <li>Le <code>UserRepository</code> capture la <code>SqliteException</code> et la convertit en exception métier typée : <code>EmailAlreadyExistsFailure</code>.</li>
      <li>Le formulaire n'est pas réinitialisé pour ne pas frustrer l'utilisateur. Un message clair et non ambigu est affiché sous le champ e-mail : <em>"Cette adresse e-mail est déjà associée à un compte MediTrack sur cet appareil. Souhaitez-vous vous connecter ?"</em> avec un lien direct vers l'écran de connexion.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Aucun enregistrement fantôme ou doublon n'est créé. L'unicité stricte de l'identifiant racine <code>users.email</code> est garantie.</p>
  </div>
</div>

<!-- SCENARIO 8.2 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.2</span> Échecs Répétés de Connexion & Verrouillage Anti-Brute-Force</span>
    <span class="badge badge-danger">Sécurité</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> Saisie consécutive de mots de passe ou de codes PIN erronés (tentative d'accès non autorisé par un tiers ou oubli de l'utilisateur).</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>À chaque échec, le système compare le hachage calculé avec le sel stocké. Constatant l'incompatibilité, il incrémente <code>users.failed_attempts</code> et enregistre un événement d'audit dans <code>security_logs (event_type='LOGIN_ATTEMPT', success=0)</code>.</li>
      <li>Au <strong>5e échec consécutif</strong>, le système active la politique de verrouillage temporaire : <code>lock_until = datetime('now', '+30 seconds')</code>. Le bouton de connexion est grisé et un compte à rebours visuel informe l'utilisateur du délai d'attente obligatoire.</li>
      <li>Au <strong>8e échec consécutif</strong>, le verrouillage passe à <strong>5 minutes</strong>. L'option de déverrouillage biométrique est temporairement révoquée, exigeant impérativement la clé de récupération (Master Recovery Key) ou le mot de passe maître après expiration du verrou.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Protection efficace contre les attaques par dictionnaire ou force brute automatisée sur terminal égaré.</p>
  </div>
</div>

<!-- SCENARIO 8.3 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.3</span> Formulaire Incomplet ou Données de Saisie Invalides</span>
    <span class="badge badge-warning">Validation</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> L'utilisateur saisit des valeurs aberrantes ou omis des champs obligatoires (ex: poids négatif de -12 kg, taille de 400 cm, date de naissance dans le futur, date de péremption de médicament antérieure à la date du jour).</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>Validation défensive à double niveau : niveau 1 au sein des contrôleurs Flutter (UI Validators réactifs) et niveau 2 au sein des <em>Value Objects</em> du Domaine (ex: <code>WeightValueObject</code> lève une <code>InvalidWeightException</code>).</li>
      <li>La soumission du formulaire est interceptée avant tout appel à la couche de persistance. Des indicateurs d'erreur contextuels en rouge s'affichent sous chaque champ incriminé avec des consignes précises (ex: <em>"Le poids doit être compris entre 2.0 et 350.0 kg"</em>).</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Aucune donnée corrompue ne franchit la frontière du domaine; respect strict des contraintes CHECK de la base relationnelle.</p>
  </div>
</div>

<!-- SCENARIO 8.4 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.4</span> Activité Physique sans Distance ni Calories Renseignées</span>
    <span class="badge badge-success">Inférence</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> L'utilisateur enregistre une séance de course à pied ou de cyclisme en renseignant uniquement la durée (ex: 30 minutes) et l'intensité, sans connaître la distance exacte ni la dépense énergétique.</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>Le <code>MetabolicCalculator</code> prend le relais : il extrait le poids actuel dans le profil patient (ex: 70 kg) et la valeur MET correspondant à la discipline et à l'intensité (ex: 8.3 MET pour course modérée).</li>
      <li>Il calcule automatiquement les calories : $\text{Calories} = 8.3 \times 70 \times (30/60) = 290.5 \text{ kcal}$.</li>
      <li>Pour les activités locomotrices, il déduit la distance estimée via la vitesse moyenne standard : $8.5 \text{ km/h} \times 0.5 \text{ h} = 4.25 \text{ km}$. L'enregistrement est tagué avec <code>data_source = 'CALCULATED_INTERNAL'</code>.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> L'historique reste exploitable pour les statistiques d'effort sans pénaliser l'utilisateur qui ne possède pas de montre GPS.</p>
  </div>
</div>

<!-- SCENARIO 8.5 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.5</span> Médicament en Expiration Imminente ou Périmé</span>
    <span class="badge badge-danger">Pharmacovigilance</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> La date système du terminal franchit l'échéance de péremption d'une boîte de médicaments enregistrée dans l'armoire à pharmacie.</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>À J-30 : Une notification préventive signale l'échéance proche afin d'anticiper le renouvellement d'ordonnance.</li>
      <li>À J-0 : Le statut du médicament bascule automatiquement à <code>EXPIRED</code>. Dans l'armoire, sa fiche est marquée d'un bandeau rouge clignotant : <em>"PÉRIMÉ — NE PAS CONSOMMER"</em>.</li>
      <li>Si ce médicament est associé à un traitement actif, l'écran de confirmation de prise affiche un avertissement critique bloquant obligeant l'utilisateur à confirmer expressément s'il procède tout de même à l'ingestion ou à substituer la boîte par un lot valide.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Sécurité sanitaire du patient et prévention des intoxications médicamenteuses.</p>
  </div>
</div>

<!-- SCENARIO 8.6 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.6</span> Stock de Médicament Insuffisant pour Honorer une Prise</span>
    <span class="badge badge-warning">Rupture Stock</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> Une prise de 2 comprimés est planifiée, mais le stock rémanent dans l'armoire à pharmacie n'est plus que de 1 comprimé (ou 0).</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>Lors de la validation de la prise, le système constate que <code>current_stock &lt; unit_dose</code>.</li>
      <li>L'application propose trois options :
        <ol>
          <li><em>"Prendre la dose partielle restante"</em> (consomme l'unité restante, passe le stock à 0 et consigne un log avec statut <code>PARTIAL_DOSE</code>).</li>
          <li><em>"J'ai racheté une boîte"</em> (ouvre instantanément la modalité de réapprovisionnement rapide, incrémente le stock de +30 comprimés puis valide la prise nominale).</li>
          <li><em>"Sauter la prise pour cause de rupture"</em> (marque l'instance <code>SKIPPED</code> avec motif <code>STOCK_DEPLETED</code> sans pénaliser l'observance volontaire).</li>
        </ol>
      </li>
      <li>Une notification prioritaire de réapprovisionnement est épinglée sur le tableau de bord.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Le stock physique ne peut en aucun cas devenir négatif (contrainte <code>CHECK (current_stock &gt;= 0)</code> respectée).</p>
  </div>
</div>

<!-- SCENARIO 8.7 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.7</span> Prise de Médicament Manquée ou Reportée (Snooze)</span>
    <span class="badge badge-primary">Adhérence</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> L'alarme de prise de 12h00 retentit alors que le patient est en réunion ou au volant.</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>Le patient appuie sur l'action <strong>[Reporter de 15 minutes]</strong> (Snooze). L'instance prévisionnelle passe à l'état transitoire <code>SNOOZED</code>. Une nouvelle alarme ponctuelle est programmée à 12h15.</li>
      <li>Si le patient valide la prise à 12h15, celle-ci s'inscrit toujours dans la fenêtre de tolérance médicale ($\pm 60$ min) : le statut d'observance reste <code>TAKEN_ON_TIME</code> (adhérence optimale préservée).</li>
      <li>Si aucune action n'est effectuée avant 14h00 (expiration de la tolérance horaire), un démon d'arrière-plan ou le réveil de l'application bascule automatiquement l'instance à l'état <code>MISSED</code>. Le taux d'observance du mois est recalculé à la baisse.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Traçabilité exacte de l'horodatage d'ingestion réel versus planifié.</p>
  </div>
</div>

<!-- SCENARIO 8.8 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.8</span> Modification ou Arrêt Anticipé d'un Traitement en Cours</span>
    <span class="badge badge-warning">Reprogrammation</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> Sur avis médical, le patient doit suspendre son traitement ou modifier la posologie (passage de 1 comprimé à 2 comprimés par jour).</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>En cas de suspension (Pause) : <code>Treatment.status = 'PAUSED'</code>. Le système annule immédiatement toutes les alarmes locales enregistrées auprès de l'OS pour les jours futurs. Les <code>planned_intakes</code> non encore échues sont marquées désactivées.</li>
      <li>En cas d'arrêt définitif : <code>Treatment.status = 'COMPLETED'</code> ou <code>'CANCELLED'</code>. L'historique passé des prises effectuées reste <strong>strictement intact et consultable</strong> (principe de non-régression de l'observance).</li>
      <li>En cas de changement de dose : l'ancienne règle posologique est close à la date du jour, et une nouvelle règle d'ordonnancement est créée sans écraser le passé.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Intégrité historique absolue et suppression propre des réveils orphelins.</p>
  </div>
</div>

<!-- SCENARIO 8.9 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.9</span> Annulation ou Report d'un Rendez-vous Médical</span>
    <span class="badge badge-neutral">Agenda</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> Le médecin contacte le patient pour décaler la consultation, ou le patient annule son rendez-vous.</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>L'utilisateur clique sur <em>"Reporter le RDV"</em> et sélectionne la nouvelle date.</li>
      <li><code>AppointmentRepository</code> révoque immédiatement les anciens identifiants d'alarmes J-2 et H-2 auprès du système hôte via <code>NotificationScheduler.cancelAlarm()</code>.</li>
      <li>De nouvelles alarmes calquées sur la nouvelle date d'échéance sont recalculées et réenregistrées.</li>
      <li>En cas d'annulation pure : le statut passe à <code>CANCELLED_BY_PATIENT</code> ou <code>CANCELLED_BY_PRACTITIONER</code> et toutes les alarmes associées sont purgées.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Élimination absolue des notifications fantômes à des dates désormais erronées.</p>
  </div>
</div>

<!-- SCENARIO 8.10 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.10</span> Notification Locale Non Délivrée (Optimisation Batterie OS)</span>
    <span class="badge badge-danger">Résilience Système</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> Certains constructeurs Android (Xiaomi MIUI, Huawei EMUI, Samsung) appliquent des politiques drastiques de gestion d'énergie (Doze Mode agressif) susceptibles de tuer les processus d'arrière-plan ou de différer les réveils.</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li>MediTrack utilise l'API <code>setExactAndAllowWhileIdle()</code> d'Android couplée à la permission <code>SCHEDULE_EXACT_ALARM</code> (ou <code>USE_EXACT_ALARM</code>) et configure les notifications dans la catégorie prioritaire <code>CATEGORY_ALARM</code>.</li>
      <li>Lors de la première installation, l'application guide le patient via un assistant pédagogique pour désactiver l'optimisation de batterie spécifique à son modèle de smartphone.</li>
      <li><strong>Mécanisme de rattrapage au réveil :</strong> À chaque lancement ou reprise de l'application au premier plan (<code>AppLifecycleState.resumed</code>), un interactor de réconciliation inspecte les <code>planned_intakes</code> : toute prise dont l'heure est échue de plus de 15 minutes sans accusé est immédiatement affichée sous forme d'alerte modale prioritaire d'écran (<em>"Rattrapage : Avez-vous pris votre traitement de 08h00 ?"</em>).</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Aucun oubli ne reste masqué, même en cas de défaillance ponctuelle du sous-système de notification de l'OS.</p>
  </div>
</div>

<!-- SCENARIO 8.11 -->
<div class="step-card">
  <div class="step-header">
    <span class="step-title"><span class="step-badge">Scénario A.11</span> Erreur de Base de Données Locale ou Absence de Réseau</span>
    <span class="badge badge-neutral">Offline-First</span>
  </div>
  <div class="step-body">
    <p><strong>Contexte & Déclencheur :</strong> Le smartphone est en mode avion dans une zone blanche médicale ou en sous-sol, ou un blocage I/O disque temporaire intervient.</p>
    <p><strong>Réaction Attendue du Système :</strong></p>
    <ul>
      <li><strong>Absence de Réseau :</strong> Aucune conséquence. MediTrack est conçu selon une architecture 100% <em>Offline-First</em>. Toutes les opérations de lecture, écriture, calculs MET et alarmes s'exécutent intégralement en local sans requérir le moindre paquet IP.</li>
      <li><strong>Erreur Disque / Conflit SQLite :</strong> Si une transaction échoue (ex: <code>SqliteException: database is locked</code>), le repository effectue jusqu'à 3 tentatives automatiques avec backoff exponentiel (50ms, 150ms, 400ms). En cas d'échec persistant, la transaction est annulée (<code>ROLLBACK</code> complet) pour laisser la base dans un état cohérent, et un message rassurant informe l'utilisateur que l'opération sera réessayée.</li>
    </ul>
    <p><strong>Règles de Cohérence Préservées :</strong> Garanties ACID totales (Atomicité, Cohérence, Isolation, Durabilité) de la persistance SQLite locale.</p>
  </div>
</div>
''';
