const String section9TechArchitectureHtml = r'''
<div class="page-break"></div>

<h1><span class="chapter-num">9</span> Architecture Technique Cible & Implémentation Flutter</h1>
<p>Pour concrétiser les exigences fonctionnelles et médicales de MediTrack, l'architecture logicielle cible s'appuie sur le framework cross-platform <strong>Flutter 3.x</strong> et respecte rigoureusement les principes de la <strong>Clean Architecture</strong> (Uncle Bob) combinée au pattern de gestion d'état réactif <strong>BLoC (Business Logic Component)</strong>.</p>

<h2>9.1 Organisation en Couches & Découplage (Clean Architecture)</h2>
<p>L'arborescence du code sépare les responsabilités en quatre couches concentriques étanches :</p>

<table>
  <thead>
    <tr>
      <th style="width: 22%;">Couche Logicielle</th>
      <th style="width: 38%;">Composants & Technologies</th>
      <th style="width: 40%;">Responsabilité & Invariants</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>1. Presentation Layer</strong></td>
      <td>Flutter Widgets, Pages, Dialogues, Custom Painters pour les jauges d'observance, <code>BlocBuilder</code>, <code>BlocListener</code>, <code>FormValidators</code>.</td>
      <td>Rendu visuel réactif, capture des interactions gestuelles du patient, affichage des erreurs et soumission des événements au BLoC. Aucune logique métier directe.</td>
    </tr>
    <tr>
      <td><strong>2. Domain Layer</strong></td>
      <td>Entités pures Dart (<code>User</code>, <code>Medication</code>, <code>Treatment</code>...), Value Objects immuables, Use Cases / Interactors, Interfaces abstraites de Repositories.</td>
      <td><strong>Noyau d'ingénierie indépendant de tout framework.</strong> Encapsule la totalité des règles d'invariance médicale, les calculs MET et l'algorithme d'observance. Zéro import Flutter.</td>
    </tr>
    <tr>
      <td><strong>3. Data Layer</strong></td>
      <td>Implémentations des Repositories (<code>TreatmentRepoImpl</code>...), Mappers/DTOs (<code>MedicationModel</code> &harr; <code>Medication</code>), DataSources locales.</td>
      <td>Traduction des entités métier en formats persistables (lignes SQL, JSON), exécution des requêtes SQL et gestion du cache local.</td>
    </tr>
    <tr>
      <td><strong>4. Core & Platform Layer</strong></td>
      <td>Driver SQLCipher, <code>flutter_local_notifications</code>, <code>local_auth</code>, <code>flutter_secure_storage</code>, adaptateurs capteurs de santé.</td>
      <td>Interfaçage avec les APIs système natives d'Android et d'iOS. Fournit les services matériels (alarmes exactes, biométrie, chiffrement matériel).</td>
    </tr>
  </tbody>
</table>

<h2>9.2 Gestion d'État Réactive (Flutter BLoC / Cubit)</h2>
<p>La gestion d'état est confiée à <strong>BLoC (flutter_bloc)</strong> pour ses garanties formelles de prévisibilité et de testabilité :</p>
<ul>
  <li><strong>Flux Unidirectionnel d'Événements :</strong> L'interface utilisateur émet des <em>Events</em> immuables (ex: <code>RecordIntakeSubmittedEvent</code>). Le BLoC correspondant traite l'événement via un Use Case dédié et émet en continu des <em>States</em> distincts (<code>IntakeLoadingState</code> &rarr; <code>IntakeSuccessState</code> ou <code>IntakeErrorState</code>).</li>
  <li><strong>Cloisonnement par Feature :</strong> Chaque module dispose de ses blocs spécialisés : <code>AuthBloc</code>, <code>ProfileBloc</code>, <code>ActivityBloc</code>, <code>MedicationInventoryBloc</code>, <code>TreatmentBloc</code>, et <code>AppointmentBloc</code>.</li>
  <li><strong>Séparation État de Saisie vs État Persisté :</strong> Les formulaires complexes (ex: assistant de création de traitement en plusieurs étapes) utilisent des Cubits légers pour piloter la validation réactive des champs avant validation définitive.</li>
</ul>

<h2>9.3 Stratégie de Persistance Chiffrée (SQLite + SQLCipher AES-256)</h2>
<p>Le stockage local repose sur une base relationnelle <strong>SQLite</strong> exploitée via le moteur cryptographique <strong>SQLCipher</strong> :</p>
<ul>
  <li><strong>Chiffrement Total au Repos (Full Database Encryption) :</strong> L'intégralité du fichier physique de base de données (pages de données, index B-Tree, journal de transactions WAL) est chiffrée de manière transparente à l'aide de l'algorithme <strong>AES-256-CBC</strong> (avec dérivation PBKDF2 de 256 000 itérations et HMAC-SHA512 par page).</li>
  <li><strong>Mode WAL (Write-Ahead Logging) :</strong> Pour maximiser les performances sur mobile et éviter les contentions lors des accès simultanés (ex: validation d'une prise pendant le rendu de l'historique), la base est configurée avec <code>PRAGMA journal_mode = WAL</code> et <code>PRAGMA synchronous = NORMAL</code>.</li>
  <li><strong>Migrations de Schéma Maîtrisées :</strong> Les évolutions futures du schéma sont gérées par un système de scripts de migration incrémentaux numérotés exécutés au démarrage au sein d'une transaction unique.</li>
</ul>

<h2>9.4 Gestion Sécurisée des Identifiants & Clés (Flutter Secure Storage)</h2>
<p>La sécurité repose sur une chaîne de confiance matérielle (Hardware Root of Trust) :</p>
<ul>
  <li>Lors de la première initialisation de MediTrack, un générateur cryptographiquement sûr (CSPRNG) produit une clé symétrique maîtresse de 256 bits.</li>
  <li>Cette clé n'est jamais écrite dans un fichier standard : elle est injectée dans le magasin sécurisé matériel de l'appareil via le plugin <code>flutter_secure_storage</code> :
    <ul>
      <li>Sur <strong>Android</strong> : Chiffrement par le <strong>Android Keystore System</strong> avec clé RSA/AES adossée à une puce matérielle sécurisée (TEE - Trusted Execution Environment ou puce Titan M / StrongBox Keymaster si disponible).</li>
      <li>Sur <strong>iOS</strong> : Stockage dans le <strong>Keychain</strong> système avec le niveau d'accessibilité maximal <code>kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly</code> protégé par la Secure Enclave.</li>
    </ul>
  </li>
  <li>En cas d'échec biométrique prolongé, la clé est verrouillée et ne peut être libérée qu'après saisie du mot de passe maître de l'utilisateur.</li>
</ul>

<h2>9.5 Moteur d'Ordonnancement et Notifications Locales Précises</h2>
<p>La survie médicale de l'application dépend de l'exactitude de ses rappels temporels :</p>
<ul>
  <li><strong>AlarmClock API sur Android :</strong> MediTrack utilise la méthode <code>scheduleExactAndAllowWhileIdle()</code> avec le drapeau <code>AlarmManager.AlarmClockInfo</code>. Ce mécanisme de plus haute priorité garantit que l'alarme sonnera à la seconde près, même si l'appareil est en veille profonde (Doze Mode actif) ou en mode économie de batterie.</li>
  <li><strong>Canaux de Notification Dédiés :</strong> Configuration d'un canal spécifique <code>meditrack_critical_intakes</code> paramétré avec <code>Importance.max</code> et <code>Priority.max</code>, doté d'une sonnerie distincte personnalisée et de vibrations insistantes.</li>
  <li><strong>Actions Interactives Intégrées :</strong> Les notifications intègrent des boutons d'action rapide permettant d'acquitter la prise (<code>Action: TAKE</code>) ou de la décaler (<code>Action: SNOOZE_15</code>) directement depuis l'écran de veille sans avoir à déverrouiller et ouvrir manuellement l'application.</li>
</ul>

<h2>9.6 Gestion Fonctionnelle des Erreurs (Pattern Result / Either)</h2>
<p>Pour éliminer les exceptions non gérées susceptibles de provoquer des crashs applicatifs intempestifs, la communication entre la couche Données et la couche Présentation adopte le pattern fonctionnel <code>Result&lt;Failure, Success&gt;</code> (inspiré du type <code>Either</code> de la bibliothèque <code>fpdart</code>) :</p>

<pre><code>// Modélisation formelle du retour d'un Use Case
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure { const DatabaseFailure(super.msg); }
class InsufficientStockFailure extends Failure { const InsufficientStockFailure(super.msg); }
class ValidationFailure extends Failure { const ValidationFailure(super.msg); }

// Exemple d'exécution dans le BLoC
final result = await recordMedicationIntakeUseCase.execute(intakeId, dose);
result.fold(
  (failure) => emit(IntakeErrorState(failure.message)),
  (success) => emit(IntakeSuccessState()),
);</code></pre>

<p>Cette rigueur de typage contraint le développeur à traiter exhaustivement chaque cas d'échec dans l'interface utilisateur.</p>

<h2>9.7 Intégration Externe et Fonctionnement Dégradé</h2>
<p>L'architecture supporte une synchronisation passive avec les écosystèmes de santé natifs des constructeurs :</p>
<ul>
  <li><strong>Google Health Connect (Android) & Apple HealthKit (iOS) :</strong> Connexion via un adaptateur abstrait <code>HealthDataSourceAdapter</code>. Cet adaptateur extrait périodiquement les pas de la journée et la fréquence cardiaque moyenne pour enrichir l'historique d'activité.</li>
  <li><strong>Principe de Dégradation Gracieuse :</strong> Si l'utilisateur refuse les permissions de santé ou si l'appareil est dépourvu de ces frameworks, l'application désactive silencieusement le connecteur sans afficher la moindre alerte d'erreur et conserve l'intégralité de ses capacités via la saisie manuelle et les calculs MET internes.</li>
</ul>
''';
