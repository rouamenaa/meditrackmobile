const String section1FunctionalHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">1</span> Présentation Fonctionnelle & Vision du Système</h1>

<h2>1.1 Contexte Médical et Problématique de l'Observance Thérapeutique</h2>
<p>Dans les systèmes de santé modernes, la mauvaise observance des prescriptions médicales constitue un enjeu sanitaire et économique majeur. Selon l'Organisation Mondiale de la Santé (OMS), dans les pays développés, <strong>seulement 50% des patients souffrant de maladies chroniques suivent fidèlement leur traitement</strong>. Cette non-observance entraîne des complications cliniques évitables, des hospitalisations en urgence et un surcoût considérable pour les régimes d'assurance maladie.</p>
<p>Parallèlement, la sédentarité croissante aggrave les facteurs de risque cardiovasculaires et métaboliques. Les patients doivent aujourd'hui jongler avec une multitude d'informations dispersées : ordonnances papier hétérogènes, boîtes de médicaments entamées sans visibilité sur le stock réel, dates de péremption oubliées, rendez-vous chez des spécialistes espacés dans le temps, et recommandations d'exercice physique difficiles à quantifier.</p>
<p>Le projet <strong>MediTrack</strong> est conçu pour combler cette rupture en offrant une plateforme mobile intégrée, agissant comme un véritable carnet de santé intelligent, autonome et centré sur le patient.</p>

<div class="callout callout-info">
  <div class="callout-title">Constat Clé d'Architecture</div>
  Pour maximiser l'adhésion du patient, l'application ne doit pas être un simple journal passif, mais un système d'assistance proactive combinant rappels fiables, suivi visuel de l'observance, gestion logistique de l'armoire à pharmacie et valorisation de l'activité physique quotidienne.
</div>

<h2>1.2 Objectifs Stratégiques et Philosophie « Offline-First »</h2>
<p>MediTrack est guidé par quatre piliers cardinaux :</p>
<ol>
  <li><strong>Souveraineté des Données et Confidentialité Absolue :</strong> Les données de santé étant hautement sensibles (au sens de l'article 9 du RGPD), l'application adopte une architecture <em>Offline-First</em>. Toutes les données médicales (traitements, profils, journaux de prises, antécédents) sont stockées localement sur le terminal de l'utilisateur, chiffrées de bout en bout par l'algorithme AES-256 (via SQLCipher). Aucune dépendance réseau obligatoire n'est requise pour le fonctionnement nominal.</li>
  <li><strong>Fiabilité Critique des Alarmes Locales :</strong> Un patient ne peut se permettre de manquer une prise d'insuline ou d'anticoagulant à cause d'une perte de connectivité ou d'une mise en veille agressive de l'OS. Le sous-système de notification s'appuie sur les mécanismes matériels d'alarmes exactes du terminal (Android <code>AlarmManager.setExactAndAllowWhileIdle</code> et iOS UserNotifications framework), garantissant le réveil ponctuel du système.</li>
  <li><strong>Ergonomie Inclusive et Accessible :</strong> L'interface est conçue pour des profils d'utilisateurs variés, allant du jeune adulte sportif au senior polymédiqué. La hiérarchie visuelle minimise la charge cognitive, privilégie des contrastes élevés, offre des boutons d'action rapide sur les notifications et propose un « Mode Discret » masquant les libellés médicaux sur l'écran verrouillé.</li>
  <li><strong>Vision Holistique de la Santé :</strong> Plutôt que de cloisonner le pilier médicamenteux, MediTrack relie l'activité physique (dépense calorique, fréquence, intensité) à l'état de santé général du patient, créant une dynamique vertueuse d'auto-prise en charge.</li>
</ol>

<h2>1.3 Typologie des Utilisateurs et Besoins Cliniques</h2>
<p>L'analyse du domaine métier a permis d'isoler quatre profils d'utilisateurs distincts :</p>

<table>
  <thead>
    <tr>
      <th style="width: 22%;">Profil Utilisateur</th>
      <th style="width: 38%;">Caractéristiques Cliniques & Habitudes</th>
      <th style="width: 40%;">Attentes Prioritaires vis-à-vis de MediTrack</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Patient Chronique Polymédiqué</strong></td>
      <td>Prend entre 3 et 8 molécules différentes par jour, réparties sur des créneaux horaires stricts (matin, midi, soir, coucher). Souvent âgé de plus de 55 ans.</td>
      <td>Rappels infaillibles, distinction visuelle des comprimés, suivi rigoureux de l'observance, alerte de réapprovisionnement pour éviter la rupture de pilulier.</td>
    </tr>
    <tr>
      <td><strong>Patient Sous Traitement Ponctuel</strong></td>
      <td>Prescription aiguë de courte durée (ex: antibiothérapie sur 7 jours, corticoïdes, antalgiques après chirurgie).</td>
      <td>Configuration rapide du traitement, respect de la durée prescrite, arrêt automatique avec clôture de l'ordonnanceur sans pollution de l'interface.</td>
    </tr>
    <tr>
      <td><strong>Usager Actif / Sportif en Reprise</strong></td>
      <td>Pratique la marche, la course à pied, le cyclisme ou la natation. Souhaite monitorer sa dépense énergétique et suivre ses objectifs d'effort.</td>
      <td>Calcul transparent des calories selon le modèle MET, suivi de la progression hebdomadaire (seuil OMS 150 min), historique des performances.</td>
    </tr>
    <tr>
      <td><strong>Aidant Familial</strong></td>
      <td>Accompagne un parent âgé ou un enfant dépendant dans la coordination de son parcours de soins.</td>
      <td>Accès rapide au contact du médecin traitant, historique horodaté des prises pour vérifier l'observance, gestion de l'agenda des rendez-vous.</td>
    </tr>
  </tbody>
</table>

<h2>1.4 Principes d'Ingénierie & Frontières du Système</h2>
<p>Pour assurer la pérennité et la cohérence conceptuelle de MediTrack, deux frontières fondamentales d'ingénierie sont posées dès la conception :</p>

<div class="callout callout-warning">
  <div class="callout-title">Règle de Séparation Métier : Inventaire vs Prescription</div>
  Il est impératif de <strong>distinguer conceptuellement l'armoire à pharmacie (l'inventaire physique des boîtes) du protocole de soins (la prescription thérapeutique)</strong> :
  <ul>
    <li>Une boîte de <em>Paracétamol 1g</em> dans l'inventaire représente une quantité physique stockée (ex: 16 comprimés, péremption 12/2027). Elle n'a aucun calendrier en soi.</li>
    <li>Le traitement prescrit par le médecin (ex: <em>"1 comprimé toutes les 8 heures si douleur"</em>) est un ordre de prise temporel qui puise dans ce stock lors de chaque validation d'ingestion.</li>
  </ul>
</div>

<div class="callout callout-danger">
  <div class="callout-title">Frontière Légale : Estimations Informatives vs Acte Médical</div>
  MediTrack est un outil d'accompagnement personnel et <strong>ne constitue en aucun cas un dispositif médical de diagnostic ou de décision thérapeutique autonome</strong>. Les algorithmes de calcul de dépense calorique (basés sur le Metabolic Equivalent of Task - MET) fournissent des estimations statistiques et non des mesures de laboratoire biométrique. Les alertes de prises rappellent les consignes du prescripteur sans jamais s'y substituer.
</div>
''';
