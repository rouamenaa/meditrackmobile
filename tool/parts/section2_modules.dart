const String section2ModulesHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">2</span> Périmètre Complet des Cinq Modules Obligatoires</h1>

<h2>2.1 Module 1 — Utilisateurs, Authentification, Profil Médical et Confidentialité</h2>
<p>Le module Utilisateur constitue le socle de sécurité et de personnalisation de MediTrack. Il garantit l'isolation stricte des données de santé du patient et pilote les droits d'accès à l'application.</p>

<h3>2.1.1 Enrôlement, Authentification & Gestion de Session</h3>
<ul>
  <li><strong>Inscription Sécurisée :</strong> L'enrôlement requiert un e-mail valide (format RFC 5322) et un mot de passe robuste répondant à des critères stricts (minimum 10 caractères, incluant au moins 1 majuscule, 1 minuscule, 1 chiffre et 1 caractère spécial). Les mots de passe ne sont jamais stockés en clair : ils sont hachés via <code>PBKDF2-HMAC-SHA256</code> (ou <code>Argon2id</code>) avec un sel cryptographique aléatoire de 128 bits généré par le moteur sécurisé du terminal.</li>
  <li><strong>Authentification Biométrique & PIN de Secours :</strong> L'utilisateur peut activer le déverrouillage biométrique (empreinte digitale Touch ID / Android BiometricPrompt, reconnaissance faciale Face ID). Un code PIN de secours à 6 chiffres, également haché et stocké de manière chiffrée, permet de déverrouiller l'application en cas d'échec biométrique ou de port de masque/gants.</li>
  <li><strong>Gestion du Cycle de Vie de Session :</strong> La session utilisateur est maintenue en mémoire volatile sous la forme d'un objet <code>UserSession</code>. Pour protéger les données en cas d'oubli du terminal, un verrouillage automatique par temporisation d'inactivité (inactivity timeout) intervient après une durée configurable (1, 5 ou 15 minutes). La déconnexion explicite purge l'état mémoire, révoque le jeton local et reverrouille le coffre-fort de données SQLCipher.</li>
  <li><strong>Réinitialisation et Changement de Mot de Passe :</strong> Le changement de mot de passe en cours de session exige la saisie préalable de l'ancien mot de passe. Dans l'architecture hors-ligne de MediTrack, la réinitialisation repose sur une <em>Master Recovery Key</em> (clé de récupération de 24 mots mnémotechniques) fournie au patient lors de son inscription initiale.</li>
  <li><strong>Gestion des Erreurs & Protection Anti-Brute-Force :</strong> Toute tentative infructueuse incrémente un compteur d'échecs. Après 5 échecs consécutifs, l'accès est temporairement bloqué pendant 30 secondes, puis 5 minutes au-delà de 8 échecs. Les messages d'erreur sont formulés de manière neutre (ex: <em>"Identifiants incorrects"</em>) pour prévenir l'énumération de comptes. Un journal d'audit de sécurité local (<code>SecurityLog</code>) consigne chaque événement d'accès sans jamais enregistrer de donnée confidentielle.</li>
</ul>

<h3>2.1.2 Profil Personnel Médical Approfondi</h3>
<p>Le profil du patient (<code>PatientProfile</code>) regroupe les données cliniques nécessaires au paramétrage des calculs et à l'assistance en situation d'urgence :</p>
<ul>
  <li><strong>Données Démographiques :</strong> Nom, prénom, date de naissance (permettant le calcul dynamique de l'âge), sexe biologique (déterminant pour le calcul du métabolisme de base).</li>
  <li><strong>Données Biométriques :</strong> Taille (en cm), Poids (en kg), Groupe sanguin (Enum : A+, A-, B+, B-, AB+, AB-, O+, O-). Le système calcule et met à jour automatiquement l'Indice de Masse Corporelle (IMC = Poids / Taille²).</li>
  <li><strong>Données Cliniques Sensibles :</strong> Liste structurée des allergies médicamenteuses et alimentaires (avec niveau de sévérité : Légère, Modérée, Sévère/Anaphylaxie), antécédents médicaux majeurs (asthme, diabète type 1/2, hypertension, insuffisance rénale), contre-indications majeures.</li>
  <li><strong>Contacts d'Urgence :</strong> Informations du médecin traitant référent et d'une personne de confiance (nom, qualité/lien de parenté, numéro de téléphone d'urgence directement appelable depuis un bouton SOS sur l'écran d'accueil).</li>
</ul>

<h3>2.1.3 Matrice des Préférences de Notification et Confidentialité</h3>
<p>L'entité <code>UserPreferences</code> permet d'ajuster finement l'expérience utilisateur :</p>
<ul>
  <li><strong>Mode Discret (Confidentialité de l'Écran de Verrouillage) :</strong> Lorsque cette option est active, les notifications locales masquent le nom commercial des molécules et affichent un message générique (<em>"MediTrack : Une prise médicamenteuse est prévue"</em>) afin d'éviter la révélation fortuite d'une pathologie à des tiers observant l'écran du smartphone.</li>
  <li><strong>Plages Silencieuses (« Ne Pas Déranger ») :</strong> Définition d'une fenêtre horaire (ex: 22h00 - 07h00) durant laquelle les notifications ordinaires sont muettes. Une exception paramétrable permet de maintenir la sonnerie pour les <em>traitements classés critiques</em> (ex: antiarythmiques).</li>
  <li><strong>Canaux & Vibrations :</strong> Choix des canaux sonores, intensité du retour haptique et rappels par défaut des rendez-vous (J-2, H-2).</li>
</ul>

<h2>2.2 Module 2 — Activité Physique, Métriques et Moteur Métabolique MET</h2>
<p>Ce module encourage un mode de vie actif en offrant une traçabilité précise des efforts physiques du patient, adaptée à son état de santé.</p>

<h3>2.2.1 Typologie et Paramètres des Activités Physiques</h3>
<p>L'entité <code>PhysicalActivity</code> supporte un catalogue complet de disciplines sportives et de rééducation :</p>
<ul>
  <li><strong>Types d'Activités Référencés :</strong> Marche (lente, modérée, rapide), Course à pied, Cyclisme (extérieur ou vélo d'appartement), Natation (brasse, crawl), Musculation / Fitness, Yoga / Stretching, Gym douce / Pilates, et Activité libre (« Autre »).</li>
  <li><strong>Métriques Collectées :</strong> Date et heure de début, durée effective (en minutes), distance parcourue (en kilomètres, conditionnée au type d'activité), niveau d'intensité perçue (Faible, Modérée, Vigoureuse), score d'effort RPE sur l'échelle de Borg (1 à 10), rythme cardiaque moyen et maximal (bpm, si montre connectée ou saisie manuelle), et notes subjectives de ressenti.</li>
</ul>

<h3>2.2.2 Moteur Algorithmique de Calcul Énergétique (Modèle MET)</h3>
<p>Pour assurer une rigueur biomécanique sans imposer de saisie complexe, MediTrack intègre le standard international <strong>Compendium of Physical Activities</strong> (Ainsworth et al., validé par l'American College of Sports Medicine) basé sur l'Équivalent Métabolique de la Tâche (MET) :</p>
<p>Par convention physiologique, <strong>1 MET correspond à la consommation énergétique au repos, soit environ 1,0 kcal/kg/heure (ou 3,5 ml d'O₂/kg/minute)</strong>.</p>

<div class="callout callout-tech">
  <div class="callout-title">Formule Fondamentale de Dépense Calorique</div>
  $$\text{Calories Estimées (kcal)} = \text{MET}_{\text{Discipline, Intensité}} \times \text{Poids du Patient (kg)} \times \left( \frac{\text{Durée (minutes)}}{60} \right)$$
</div>

<table>
  <thead>
    <tr>
      <th>Type d'Activité</th>
      <th>Intensité Faible</th>
      <th>Intensité Modérée</th>
      <th>Intensité Vigoureuse</th>
      <th>Formule de Distance Déduite (si omise)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Marche</strong></td>
      <td>2.8 MET (3 km/h)</td>
      <td>3.8 MET (4.8 km/h)</td>
      <td>5.0 MET (6.5 km/h)</td>
      <td>Distance = Vitesse(km/h) × Durée(h)</td>
    </tr>
    <tr>
      <td><strong>Course à pied</strong></td>
      <td>6.0 MET (Jogging lent)</td>
      <td>8.3 MET (8.5 km/h)</td>
      <td>11.5 MET (11 km/h)</td>
      <td>Distance = Vitesse(km/h) × Durée(h)</td>
    </tr>
    <tr>
      <td><strong>Cyclisme</strong></td>
      <td>4.0 MET (&lt; 15 km/h)</td>
      <td>6.8 MET (16-19 km/h)</td>
      <td>10.0 MET (20-25 km/h)</td>
      <td>Distance = Vitesse(km/h) × Durée(h)</td>
    </tr>
    <tr>
      <td><strong>Natation</strong></td>
      <td>4.8 MET (Plaisir)</td>
      <td>7.0 MET (Brasse active)</td>
      <td>9.8 MET (Crawl vigoureux)</td>
      <td>Non applicable sans capteur</td>
    </tr>
    <tr>
      <td><strong>Musculation / Renforcement</strong></td>
      <td>3.0 MET (Léger)</td>
      <td>5.0 MET (Circuit training)</td>
      <td>6.0 MET (Charges lourdes)</td>
      <td>Non applicable (Distance = 0)</td>
    </tr>
    <tr>
      <td><strong>Yoga / Gym Douce</strong></td>
      <td>2.0 MET (Stretching)</td>
      <td>2.8 MET (Hatha Yoga)</td>
      <td>4.0 MET (Vinyasa / Power)</td>
      <td>Non applicable (Distance = 0)</td>
    </tr>
  </tbody>
</table>

<p>Le système calcule également le Métabolisme de Base (BMR) selon l'équation de Mifflin-St Jeor en fonction du sexe, du poids, de la taille et de l'âge stockés dans le profil.</p>

<h3>2.2.3 Distinction Rigoureuse des Sources de Données</h3>
<p>L'architecture isole strictement la provenance de chaque métrique via l'attribut <code>DataSource</code> :</p>
<ul>
  <li><code>MANUAL_DECLARATIVE</code> : Saisie directe par l'utilisateur via le formulaire mobile.</li>
  <li><code>CALCULATED_INTERNAL</code> : Données inférées par le moteur algorithmique local (ex: calories déduites du MET et du poids profil).</li>
  <li><code>EXTERNAL_SENSOR_SYNC</code> : Données synchronisées de manière asynchrone depuis les frameworks natifs du terminal (Google Health Connect sur Android, Apple HealthKit sur iOS), telles que le podomètre passif ou le capteur cardiofréquencemètre optique.</li>
</ul>

<h3>2.2.4 Objectifs, Statistiques et Progression</h3>
<p>L'entité <code>ActivityGoal</code> permet de définir des cibles temporelles (quotidiennes ou hebdomadaires). Par défaut, MediTrack propose le seuil préconisé par l'OMS de <strong>150 minutes d'activité aérobie d'intensité modérée par semaine</strong> (ou 75 minutes d'activité vigoureuse). Le tableau de bord affiche un anneau de progression réactif calculant le pourcentage d'accomplissement de la période glissante.</p>

<h2>2.3 Module 3 — Médicaments et Armoire à Pharmacie Personnelle</h2>
<p>Ce module assure la gestion logistique rigoureuse de la pharmacie familiale de l'utilisateur, indépendamment des prescriptions en cours.</p>

<h3>2.3.1 Propriétés et Caractéristiques Galéniques</h3>
<p>Chaque spécialité pharmaceutique est modélisée par l'entité <code>Medication</code>, pourvue d'un ensemble de descripteurs normalisés :</p>
<ul>
  <li><strong>Dénomination Commerciale & DCI :</strong> Nom de spécialité de marque (ex: <em>"Doliprane"</em>, <em>"Kardegic"</em>) couplé à sa Dénomination Commune Internationale (ex: <em>"Paracétamol"</em>, <em>"Acide acétylsalicylique"</em>), indispensable pour détecter les doublons de molécules prescrits sous des noms de marques distincts.</li>
  <li><strong>Codes Réglementaires :</strong> Code CIS (Code d'Identification de Spécialité) ou CIP (Code Identifiant Présentation à 13 chiffres) permettant l'identification unique dans les répertoires officiels.</li>
  <li><strong>Dosage et Unité :</strong> Modélisé par le Value Object <code>Dosage</code> (valeur numérique et unité : mg, g, µg, ml, UI, bouffée, gouttes).</li>
  <li><strong>Forme Galénique (Pharmaceutique) :</strong> Enumération <code>GalenicForm</code> (Comprimé sécable, Gélule, Sirop, Solution buvable, Sachet poudre, Pommade/Crème, Gel, Collyre, Gouttes auriculaires, Aérosol/Inhalateur, Injectable, Patch transdermique, Suppositoire).</li>
  <li><strong>Voie d'Administration :</strong> Enumération <code>AdministrationRoute</code> (Orale, Sublinguale, Cutanée, Inhalée, Oculaire, Auriculaire, Nasale, Intraveineuse, Sous-cutanée, Rectale).</li>
</ul>

<h3>2.3.2 Gestion du Stock et Alertes Logistiques</h3>
<p>Pour prévenir les ruptures thérapeutiques, l'application suit au plus près les unités physiques possédées :</p>
<ul>
  <li><code>currentStock</code> : Nombre d'unités de prise immédiatement disponibles (ex: 24 comprimés, 150 ml).</li>
  <li><code>minStockThreshold</code> : Seuil critique d'alerte paramétrable (ex: 6 comprimés, soit 2 jours de traitement). Lorsque <code>currentStock <= minStockThreshold</code>, un événement d'alerte logistique est émis.</li>
  <li><code>StockMovement</code> : Table d'audit enregistrant chaque entrée (achat d'une nouvelle boîte, réapprovisionnement) et chaque sortie (consommation liée à une prise validée, mise au rebut de produit périmé ou endommagé).</li>
</ul>

<h3>2.3.3 Suivi des Péremptions & Numéros de Lot</h3>
<p>La date de péremption (<code>expiryDate</code>) et le numéro de lot fabricant (<code>batchNumber</code>) permettent une traçabilité sanitaire de l'armoire :</p>
<ul>
  <li><strong>Alerte J-30 (Préventive) :</strong> Notifie le patient que la boîte expire sous 30 jours, l'invitant à anticiper le renouvellement d'ordonnance.</li>
  <li><strong>Alerte J-7 (Imminente) :</strong> Avertissement renforcé recommandant de planifier le passage en pharmacie.</li>
  <li><strong>Alerte J-0 (Péremption Avérée) :</strong> Le médicament passe au statut <code>EXPIRED</code>. Il est immédiatement marqué d'un badge rouge d'interdiction et un message rappelle les consignes d'élimination éco-responsable (retour en pharmacie via le circuit Cyclamed).</li>
</ul>

<h2>2.4 Module 4 — Traitements, Prescriptions, Planning et Observance</h2>
<p>Cœur opérationnel de MediTrack, ce module orchestre la planification temporelle des prises et mesure l'adhésion thérapeutique du patient.</p>

<h3>2.4.1 Découpage Conceptuel à Trois Paliers</h3>
<p>Pour éviter toute ambiguïté et permettre une adaptabilité maximale, l'architecture sépare nettement trois niveaux d'abstraction :</p>
<ol>
  <li><strong>Palier Stratégique — Le Traitement (<code>Treatment</code>) :</strong> Représente le protocole médical global d'une pathologie (ex: <em>"Protocole Diabète Type 2"</em>). Il porte l'intitulé, le médecin prescripteur, la date de début, la date de fin (ou l'indicateur <code>isChronic = true</code>), les consignes générales, et son statut (<code>ACTIVE</code>, <code>PAUSED</code>, <code>COMPLETED</code>, <code>CANCELLED</code>).</li>
  <li><strong>Palier Tactique — L'Élément Prescrit & la Règle Posologique (<code>PrescriptionItem</code> & <code>IntakeSchedule</code>) :</strong> Un traitement agrège un ou plusieurs médicaments prescrits. Chaque élément prescrit spécifie la dose unitaire (ex: <em>"1 comprimé de 500mg"</em>) et s'associe à une règle temporelle :
    <ul>
      <li><em>Fréquence :</em> Quotidienne, Jours pairs/impairs, Jours de semaine ciblés (ex: Lundi, Mercredi, Vendredi), Intervalle fixe (ex: toutes les 8h), ou Si besoin / PRN (avec dose journalière plafond).</li>
      <li><em>Heures Programmées :</em> Liste de créneaux horaires fixes (ex: 08:00, 12:30, 20:00).</li>
      <li><em>Conditions d'Ingestion :</em> Enum <code>MealCondition</code> (À jeun, Avant repas, Pendant repas, Après repas, Indifférent, Au coucher).</li>
    </ul>
  </li>
  <li><strong>Palier Opérationnel — L'Instance Prévisionnelle & la Trace Réelle (<code>PlannedIntake</code> & <code>IntakeLog</code>) :</strong>
    <ul>
      <li><code>PlannedIntake</code> : Entité instanciée par l'ordonnanceur prédictif pour chaque créneau à venir sur un horizon glissant de 14 jours. Elle porte l'heure exacte programmée (<code>scheduledDateTime</code>), la tolérance horaire ($\pm 60$ min), et son état transitoire (<code>SCHEDULED</code>, <code>NOTIFIED</code>, <code>TAKEN</code>, <code>MISSED</code>, <code>SNOOZED</code>, <code>SKIPPED</code>).</li>
      <li><code>IntakeLog</code> : Enregistrement immuable de l'événement physique d'ingestion. Il horodate la prise réelle (<code>actualTakenDateTime</code>), consigne la quantité réellement consommée, et archive d'éventuelles observations (ex: nausée, oubli, prise partielle).</li>
    </ul>
  </li>
</ol>

<h3>2.4.2 Moteur d'Ordonnancement et Décrémentation Atomique</h3>
<p>Lorsqu'une alarme retentit et que le patient confirme la prise (soit depuis la notification push, soit dans l'application) :</p>
<ul>
  <li>La <code>PlannedIntake</code> passe à l'état <code>TAKEN</code>.</li>
  <li>Un <code>IntakeLog</code> horodaté est persisté.</li>
  <li>Le stock rémanent du médicament associé est décrémenté de manière atomique au sein de la même transaction SQLite : <code>medications.current_stock = current_stock - dose_quantity</code>.</li>
  <li>Si le stock franchit le seuil critique, l'alerte logistique est immédiatement enchaînée.</li>
</ul>

<h3>2.4.3 Mesure Scientifique de l'Observance Thérapeutique</h3>
<p>MediTrack implémente l'algorithme standardisé de calcul d'adhérence thérapeutique recommandé par l'OMS et l'ESPACOMP (International Society for Medication Adherence) :</p>

<div class="callout callout-tech">
  <div class="callout-title">Indicateur d'Observance Thérapeutique Globale</div>
  $$\text{Taux d'Observance (\%) } = \left( \frac{\sum \text{Prises validées dans la fenêtre de tolérance}}{\sum \text{Prises planifiées échues sur la période}} \right) \times 100$$
</div>

<p>Le taux est ventilé par traitement et sur des fenêtres temporelles glissantes (7 jours, 30 jours, 90 jours). L'application catégorise visuellement la régularité du patient :</p>
<ul>
  <li><span class="badge badge-success">Optimale (&ge; 90%)</span> : Adhérence excellente, efficacité pharmacologique maximale.</li>
  <li><span class="badge badge-primary">Bonne (80% - 89%)</span> : Quelques retards mineurs sans danger thérapeutique majeur.</li>
  <li><span class="badge badge-warning">Modérée (70% - 79%)</span> : Oublis réguliers nécessitant un réajustement des horaires ou des rappels.</li>
  <li><span class="badge badge-danger">Critique (&lt; 70%)</span> : Risque élevé d'échec thérapeutique, alerte proposant d'en échanger avec le médecin.</li>
</ul>

<h2>2.5 Module 5 — Rendez-vous Médicaux, Praticiens et Consultations Réalisées</h2>
<p>Ce module orchestre la coordination du parcours de soins en reliant les consultations programmées aux praticiens de santé et en archivant les traces cliniques consécutives.</p>

<h3>2.5.1 Référentiel des Praticiens & Établissements</h3>
<ul>
  <li><strong>Praticien (<code>Practitioner</code>) :</strong> Nom, prénom, titre (Dr, Pr), spécialité médicale normalisée (Médecine générale, Cardiologie, Dermatologie, Ophtalmologie, Rhumatologie, Psychiatrie, Kinésithérapie, Dentisterie, etc.), numéro RPPS/Adeli (optionnel), coordonnées téléphoniques et e-mail.</li>
  <li><strong>Établissement de Santé (<code>HealthFacility</code>) :</strong> Nom de la structure (Cabinet libéral, Maison de santé, Hôpital, Polyclinique), adresse postale détaillée, bâtiment/étage, coordonnées de géolocalisation GPS (latitude/longitude permettant le calcul direct de guidage routier via l'application de navigation du smartphone).</li>
</ul>

<h3>2.5.2 Rendez-vous Planifié (<code>Appointment</code>)</h3>
<p>L'entité <code>Appointment</code> structure l'agenda médical :</p>
<ul>
  <li>Date et heure de début, durée estimée de la séance (ex: 30 minutes).</li>
  <li>Motif de la consultation (ex: <em>"Bilan cardiologique annuel"</em>, <em>"Renouvellement ordonnance"</em>, <em>"Douleurs articulaires"</em>).</li>
  <li>Modalité : Présentiel ou Téléconsultation (avec stockage sécurisé de l'URL chiffrée de visioconférence).</li>
  <li>Cycle de vie du statut (<code>AppointmentStatus</code>) : <code>SCHEDULED</code> (Planifié), <code>CONFIRMED</code> (Confirmé), <code>RESCHEDULED</code> (Reporté), <code>CANCELLED_BY_PATIENT</code> (Annulé par le patient), <code>CANCELLED_BY_PRACTITIONER</code> (Annulé par le cabinet), <code>COMPLETED</code> (Réalisé), <code>MISSED</code> (Non honoré).</li>
  <li><strong>Rappels Préalables Multi-Échéances :</strong> Programmation de deux alertes locales distinctes : à <strong>J-2 (48 heures avant)</strong> pour préparer les bilans nécessaires et permettre un désistement dans les temps; et à <strong>H-2 (2 heures avant)</strong> avec raccourci de calcul d'itinéraire.</li>
</ul>

<h3>2.5.3 Compte-Rendu de Consultation Réalisée (<code>ConsultationRecord</code>)</h3>
<div class="callout callout-info">
  <div class="callout-title">Distinction Métier Fondamentale</div>
  L'<code>Appointment</code> est l'événement temporel planifié dans l'agenda. Le <code>ConsultationRecord</code> est la <strong>mémoire clinique de la consultation effective</strong> créée une fois le rendez-vous accompli.
</div>
<p>Le compte-rendu post-visite permet de consigner :</p>
<ul>
  <li>La date et l'heure effectives de tenue.</li>
  <li>Le compte-rendu synthétique et les recommandations verbales du praticien.</li>
  <li>Les constantes physiologiques relevées pendant l'examen (Tension artérielle systolique/diastolique en mmHg, Poids en kg, Fréquence cardiaque au repos en bpm).</li>
  <li>Les prescriptions reçues : un pont direct permet de générer instantanément un nouveau <code>Treatment</code> MediTrack à partir des éléments relevés.</li>
  <li>Les examens complémentaires prescrits (analyses sanguines, radiographie, IRM) avec date limite recommandée.</li>
</ul>
''';
