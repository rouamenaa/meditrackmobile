const String section10BusinessRulesHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">10</span> Règles Métier, Sécurité et Décisions de Conception</h1>
<p>Cette section consigne les contraintes réglementaires, les règles d'intégrité de domaine et les arbitrages d'ingénierie qui encadrent le comportement de MediTrack.</p>

<h2>10.1 Cloisonnement et Isolation Multi-Utilisateurs</h2>
<p>Bien que MediTrack soit principalement une application mobile monoposte, son modèle relationnel et son architecture logicielle supportent nativement le multi-comptes local (ex: tablette familiale ou smartphone partagé entre deux conjoints) :</p>
<ul>
  <li><strong>Clé Partitionnelle Obligatoire :</strong> Chaque table de données (profils, activités, médicaments, traitements, rendez-vous) possède une colonne <code>user_id</code> obligatoire (clé étrangère vers <code>users.id</code>).</li>
  <li><strong>Filtre Systématique des Requêtes :</strong> Tous les repositories appliquent automatiquement la clause <code>WHERE user_id = :activeUserId</code> injectée dynamiquement via le <code>SessionManager</code>. Il est structurellement impossible qu'un utilisateur accède aux médicaments ou rendez-vous d'un autre profil enregistré sur le même terminal.</li>
</ul>

<h2>10.2 Validation des Données Saisies & Invariance de Domaine</h2>
<p>La fiabilité du dossier médical repose sur des contrôles stricts imposés aux frontières du domaine :</p>
<ul>
  <li><strong>Contrôles Biométriques :</strong> Poids borné entre 2.0 kg et 350.0 kg; taille bornée entre 40 cm et 250 cm; dates de naissance obligatoirement antérieures à la date du jour.</li>
  <li><strong>Contrôles Pharmaceutiques :</strong> Posologie unitaire strictement positive (&gt; 0); seuil d'alerte de stock &ge; 0; date de péremption obligatoirement ultérieure à la date de saisie du lot.</li>
  <li><strong>Contrôles Temporels :</strong> Pour un traitement à durée déterminée, la date de fin (<code>endDate</code>) doit être strictement postérieure à la date de début (<code>startDate</code>). Pour un rendez-vous, la durée de consultation doit être &ge; 5 minutes et &le; 480 minutes (8 heures).</li>
</ul>

<h2>10.3 Cohérence Transactionnelle ACID des Prises et de l'Inventaire</h2>
<p>L'opération de prise médicamenteuse modifie simultanément plusieurs agrégats du système. Pour bannir tout état incohérent (ex: prise enregistrée mais stock non décrémenté en cas de coupure de batterie), l'opération est exécutée au sein d'une <strong>transaction SQLite ACID unique</strong> :</p>
<pre><code>BEGIN TRANSACTION;
  -- 1. Mise à jour du statut de l'instance prévisionnelle
  UPDATE planned_intakes SET status = 'TAKEN' WHERE id = :intakeId;

  -- 2. Insertion du journal immuable d'observance
  INSERT INTO intake_logs (id, planned_intake_id, actual_taken_datetime, actual_dose, status, is_within_tolerance)
  VALUES (:logId, :intakeId, :actualTime, :dose, 'TAKEN_ON_TIME', 1);

  -- 3. Décrémentation atomique du stock d'armoire
  UPDATE medications SET current_stock = current_stock - :dose WHERE id = :medicationId;

  -- 4. Audit du mouvement d'inventaire
  INSERT INTO stock_movements (id, medication_id, movement_type, quantity_change, stock_after, movement_date)
  VALUES (:movementId, :medicationId, 'TREATMENT_CONSUMPTION', -:dose, :newStock, :actualTime);
COMMIT;</code></pre>
<p>Si une seule de ces instructions échoue (ex: verrouillage de base ou contrainte CHECK violée), l'ensemble du bloc est immédiatement annulé (<code>ROLLBACK</code>), préservant l'intégrité de l'armoire.</p>

<h2>10.4 Gestion Rigoureuse des Dates, Heures et Fuseaux Horaires</h2>
<p>La gestion temporelle dans une application de santé mobile est source fréquente de régressions lors des voyages transfrontaliers ou des passages à l'heure d'été/hiver :</p>
<ul>
  <li><strong>Persistance Universelle UTC :</strong> Tous les horodatages d'événements passés (séances d'activité, journaux d'ingestion réels, dates de consultations tenues, logs d'audit) sont stockés sous forme de chaînes de caractères <strong>ISO-8601 UTC</strong> (ex: <code>2026-10-22T20:15:00Z</code>).</li>
  <li><strong>Invariance Locale des Heures de Prise (LocalTime Invariance) :</strong> Les heures cibles de prise d'un traitement (ex: <em>"Prendre à 08:00 le matin au petit-déjeuner"</em>) sont stockées sous forme de chaîne <code>HH:mm</code> décorrélée du fuseau horaire. Si le patient voyage de Paris (UTC+1) à New York (UTC-5), son rappel continue de retentir à 08h00 heure locale de New York, respectant son rythme biologique d'éveil sans nécessiter de conversion d'horaires.</li>
  <li><strong>Réconciliation lors du Changement de Fuseau de l'OS :</strong> Un récepteur d'événements système (<code>ACTION_TIMEZONE_CHANGED</code> sur Android et <code>NSSystemClockDidChangeNotification</code> sur iOS) déclenche une réévaluation immédiate des alarmes programmées pour recalculer les triggers en fonction du nouveau décalage horaire.</li>
</ul>

<h2>10.5 Algorithme Déterministe Anti-Doublons de Notifications</h2>
<p>Pour éviter la saturation du système de notification de l'OS (qui impose une limite matérielle d'environ 500 alarmes simultanées sur Android) et prévenir tout doublon de sonnerie :</p>
<ul>
  <li><strong>Horizon Glissant Borne :</strong> L'ordonnanceur ne programme jamais d'alarmes au-delà de <strong>14 jours glissants</strong>. Un travail périodique d'arrière-plan réévalue et prolonge l'horizon chaque semaine.</li>
  <li><strong>Identifiant Numérique 32-bit Déterministe :</strong> Les APIs natives de notification exigent un identifiant entier 32 bits (<code>int32</code>). Pour mapper les UUIDs v4 des entités sans risque de collision, MediTrack utilise un hachage déterministe FNV-1a (Fowler-Noll-Vo) combinant l'UUID de l'instance et le type d'échéance :
    <pre><code>int generateNotificationId(String entityId, String scheduleType) {
  final input = '$entityId-$scheduleType';
  var hash = 0x811c9dc5;
  for (var i = 0; i < input.length; i++) {
    hash ^= input.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0x7FFFFFFF; // Reste dans l'espace entier positif 31 bits
  }
  return hash;
}</code></pre>
  </li>
</ul>

<h2>10.6 Protection des Données Personnelles et Médicales (RGPD & HDS)</h2>
<p>Conformément au Règlement Général sur la Protection des Données (RGPD - Règlement UE 2016/679) et aux référentiels de sécurité des Données de Santé :</p>
<ul>
  <li><strong>Principe de Minimisation des Données :</strong> Seules les informations strictement indispensables au bon fonctionnement thérapeutique et métabolique sont collectées. L'application ne requiert aucun numéro de sécurité sociale ni donnée financière.</li>
  <li><strong>Droit à l'Oubli et Destruction Cryptographique (Crypto-Shredding) :</strong> Lorsque l'utilisateur demande la suppression définitive de son compte, outre la commande <code>DROP DATABASE</code> sur SQLite, MediTrack révoque et détruit la clé maîtresse AES-256 stockée dans le Keystore/Keychain. Même en cas d'analyse légiste (forensic) de la mémoire flash physique du smartphone, les secteurs résiduels sont rendus mathématiquement indéchiffrables.</li>
  <li><strong>Droit à la Portabilité :</strong> L'utilisateur peut à tout instant exporter l'intégralité de ses données sous la forme d'un dossier standardisé JSON chiffré et d'un rapport de synthèse médical au format PDF.</li>
</ul>

<h2>10.7 Clause de Non-Responsabilité Médicale & Avertissement Éthique</h2>
<div class="callout callout-warning">
  <div class="callout-title">Avertissement Légal Obligatoire Inclus dans l'Application</div>
  <p><em>« MediTrack est une application logicielle d'accompagnement personnel destinée à faciliter l'organisation quotidienne des traitements, le suivi des rendez-vous et l'enregistrement de l'activité physique. MediTrack ne constitue pas un dispositif médical de diagnostic, d'évaluation clinique ou de prescription thérapeutique. Les calculs de dépense énergétique et les recommandations d'activités physiques sont des estimations biomécaniques indicatives basées sur des modèles statistiques (MET - Metabolic Equivalent of Task). Elles ne remplacent en aucun cas l'avis, l'examen ou les directives d'un médecin ou d'un professionnel de santé qualifié. En cas de malaise, de réaction indésirable ou de doute sur la conduite d'un traitement, consultez immédiatement votre médecin ou composez le numéro des services d'urgence médicale (15 / 112). »</em></p>
</div>
''';
