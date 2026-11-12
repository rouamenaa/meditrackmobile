# MediTrack Mobile

Application mobile de suivi médical personnel (Flutter + Node.js/MongoDB) : comptes patients,
rappels de prise de médicaments, catalogue de médicaments, suivi d'activité physique et gestion des rendez-vous.

> Projet académique — le code, les commentaires et l'interface sont en français.

---

## Sommaire

- [Aperçu](#aperçu)
- [Stack technique](#stack-technique)
- [Structure du projet](#structure-du-projet)
- [Prérequis](#prérequis)
- [1. Lancer le backend](#1-lancer-le-backend)
- [2. Lancer l'application](#2-lancer-lapplication)
- [3. Construire un APK](#3-construire-un-apk)
- [Comptes et vérification e-mail](#comptes-et-vérification-e-mail)
- [Modules](#modules)
- [Synchronisation Traitements (Option B)](#synchronisation-traitements-option-b)
- [Design system](#design-system)
- [Tests et qualité](#tests-et-qualité)
- [Dépannage](#dépannage)

---

## Aperçu

| Écran | Rôle |
| --- | --- |
| **Tableau de bord** (`home_screen.dart`) | Prochaine prise de médicament (validation en un tap), prochain rendez-vous, traitements du jour, alerte de fin de traitement |
| **Connexion / inscription** | Inscription avec code de vérification envoyé par e-mail, mot de passe oublié |
| **Médicaments** | Catalogue personnel (ajout, modification, suppression), gestion du stock, alertes stock bas, dates d'expiration, **recherche automatique via API RxNorm (NIH)** |
| **Traitements** | Création d'un protocole (dose, horaires, dates), historique des prises, adhérence hebdomadaire, rappels locaux, **sync backend** |
| **Rendez-vous** | Liste des rendez-vous et historique, création (praticien, lieu, motif, présentiel/téléconsultation) |
| **Activité physique** | Journal d'activités (type, durée, intensité, calories) |
| **Profil** | Informations personnelles, photo, médecins référents, export PDF du dossier médical, déconnexion |

**Architecture des données**

- **Comptes, authentification, profil** → API Node.js + MongoDB.
- **Données de santé** (traitements, prises, médicaments, rendez-vous, activités) → **SQLite locale** (`meditrack.db`), via `sqflite`.
- **Synchronisation traitements** → API REST `/treatments` (bidirectionnelle, fire-and-forget, offline-first).
- La session est conservée dans `shared_preferences` (`user_id` + token JWT) et restaurée au lancement.

---

## Stack technique

**Application**

- Flutter / Dart (SDK `^3.13.5`)
- `provider` (état), `sqflite` + `path` (base locale), `shared_preferences` (session)
- `http` (API), `crypto`, `flutter_local_notifications` + `timezone` (rappels)
- `image_picker` (photo de profil), `pdf` (export du dossier médical)

**Backend**

- Node.js, Express 5, MongoDB via Mongoose
- JWT (`jsonwebtoken`), `bcryptjs`, `nodemailer` (vérification e-mail), `multer` (upload photo), `morgan` (logs)

---

## Structure du projet

```
meditrackmobile/
├── lib/
│   ├── main.dart                     # entrée : Provider + restauration de session
│   ├── config.dart                   # URL de l'API (surchargeable par --dart-define)
│   ├── database/database_helper.dart # base SQLite partagée par les modules
│   └── features/
│       ├── auth/                     # connexion, inscription, vérification, profil
│       ├── appointments/             # rendez-vous (modèle, provider, écrans, widgets)
│       ├── medications/              # catalogue médicaments, stock, API RxNorm (NIH)
│       ├── treatments/               # traitements, prises, historique, rappels + sync API
│       ├── physical_activity/        # journal d'activité
│       └── profile/                  # export PDF
├── meditrack_backend/                # API Express + MongoDB
│   ├── server.js
│   ├── routes/ controllers/ models/ middleware/ config/
│   └── .env                          # secrets locaux (non versionné)
├── tool/                             # générateur de la spécification HTML du projet
├── test/                             # tests (modèles, widget, intégration)
│   ├── appointments_test.dart
│   └── features/
│       ├── appointments/appointment_card_test.dart
│       ├── physical_activity/physical_activity_test.dart
│       └── treatments/treatment_test.dart
├── dart_test.yaml                    # reporter `expanded` pour `flutter test`
└── assets/                           # icônes / images
```

---

## Prérequis

- **Flutter** (canal stable) et un SDK Android configuré
- **Node.js 18+** et **npm**
- **MongoDB** en local (`mongod` sur `127.0.0.1:27017`) ou une URI MongoDB distante
- Un **émulateur Android** ou un **téléphone en mode développeur** (débogage USB activé)

---

## 1. Lancer le backend

```bash
cd meditrack_backend
npm install
```

Créer `meditrack_backend/.env` (fichier ignoré par Git) :

```env
PORT=3000
MONGO_URI=mongodb://127.0.0.1:27017/meditrack
JWT_SECRET=change_me
# Envoi des codes de vérification par e-mail
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_USER=adresse@gmail.com
SMTP_PASS=mot_de_passe_application
SMTP_FROM="MediTrack <adresse@gmail.com>"
```

Démarrer MongoDB, puis :

```bash
npm run dev        # ou : npm start
```

Vérification :

```bash
curl http://localhost:3000/health
# {"status":"ok"}
```

Le serveur écoute sur `0.0.0.0:3000` (donc accessible depuis le téléphone sur le même réseau Wi-Fi).

### Endpoints principaux

| Méthode | Route | Auth | Description |
| --- | --- | --- | --- |
| `GET` | `/health` | — | État du serveur |
| `POST` | `/users` | — | Inscription |
| `POST` | `/users/login` | — | Connexion (renvoie un token JWT) |
| `POST` | `/users/verify/send` · `/users/verify/confirm` | — | Envoi / validation du code e-mail |
| `POST` | `/users/forgot-password` · `/users/reset-password` | — | Réinitialisation du mot de passe |
| `GET`/`PUT` | `/users/:id` | Bearer | Lire / modifier le profil |
| `PUT` | `/users/:id/password` | Bearer | Changer le mot de passe |
| `POST` | `/users/:id/photo` | Bearer | Upload de la photo de profil |
| `GET`/`POST`/`DELETE` | `/users/:id/medecins…` | Bearer | Médecins référents |
| `GET`/`POST`/`PUT`/`DELETE` | `/treatments` | Bearer | **CRUD traitements (sync)** |

---

## 2. Lancer l'application

L'URL de l'API est définie dans `lib/config.dart` :

```dart
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000', // émulateur Android → PC hôte
);
```

### Émulateur Android

```bash
flutter pub get
flutter run
```

`10.0.2.2` est l'alias de la machine hôte vu depuis l'émulateur : rien à configurer.

### Téléphone réel

Le téléphone doit être sur le **même Wi-Fi** que le PC, et le port `3000` autorisé dans le
pare-feu Windows. Récupérer l'IP du PC (`ipconfig`), puis :

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.69:3000
```

> ⚠️ Sans `--dart-define=API_BASE_URL=…`, l'application utilise `10.0.2.2`, qui n'existe pas
> sur un vrai téléphone : l'inscription/connexion échouera. Pensez à l'ajouter dans la
> configuration de lancement Android Studio (Run → Edit Configurations → *Additional run args*).

---

## 3. Construire un APK

```bash
# Émulateur
flutter build apk --debug

# Téléphone réel
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.69:3000
```

APK généré : `build/app/outputs/flutter-apk/app-debug.apk`

Installation :

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## Comptes et vérification e-mail

1. **Inscription** → le backend crée le compte (`email_verifie = false`) et envoie un code.
2. **Vérification** → saisir le code dans l'écran de vérification ; le compte passe à `email_verifie = true`.
3. **Connexion** → renvoie un JWT stocké localement ; la session est restaurée au prochain lancement.

Si l'e-mail n'arrive pas : vérifier les logs du backend (morgan), le dossier spam, et que
`SMTP_*` est correctement renseigné (Gmail nécessite un **mot de passe d'application**).

---

## Modules

| Module | Dossier |
| --- | --- |
| Authentification & profil | `lib/features/auth/` |
| Rendez-vous | `lib/features/appointments/` |
| **Médicaments** | **`lib/features/medications/`** |
| Traitements & rappels | `lib/features/treatments/` |
| Médicaments (catalogue) | `lib/features/medications/` |
| Activité physique | `lib/features/physical_activity/` |
| Export PDF | `lib/features/profile/` |

> Convention d'équipe : chaque module est autonome. On n'édite pas le code d'un autre module ;
> on consomme uniquement ses API publiques (`AppointmentProvider`, `TreatmentRepository`, `MedicationRepository`, etc.).
> La base SQLite est partagée via `DatabaseHelper` (tables créées en `IF NOT EXISTS`).

---

<<<<<<< HEAD
## Module Médicaments — Valeur Ajoutée

Le module médicaments intègre une **recherche automatique via l'API RxNorm** (National Institutes of Health, USA) :

- **API** : `https://rxnav.nlm.nih.gov/REST` — gratuite, sans clé, base pharmaceutique officielle
- **Fonctionnement** : dans le formulaire d'ajout, l'utilisateur tape le nom d'un médicament (ex : `ibuprofen`, `amoxicillin`) → l'API retourne une liste de résultats avec dosage et forme pharmaceutique → un tap remplit automatiquement le formulaire
- **Données récupérées** : nom générique, dosage (ex : `200 MG`), forme (Oral Tablet, Capsule, Injection…), identifiant RxNorm (`rxcui`)
- **Stockage** : les médicaments sont sauvegardés **localement en SQLite** (`medications` table dans `meditrack.db`)

```
lib/features/medications/
├── models/medication.dart              # modèle + enum MedicationForm
├── repositories/medication_repository.dart  # CRUD SQLite
├── screens/
│   ├── medications_screen.dart         # liste avec recherche
│   ├── medication_detail_screen.dart   # détail + gestion stock
│   └── medication_form_screen.dart     # formulaire + intégration RxNorm
└── services/
    └── drug_search_service.dart        # client API RxNorm (NIH)
```

---

## Synchronisation Traitements (Option B)

Le module **treatments** implémente une **synchronisation bidirectionnelle** avec l'API REST `/treatments` :

- **Local-first** : SQLite reste la source de vérité (offline, rapide, pas de blocage UI).
- **Push (fire-and-forget)** : chaque `create`, `update`, `delete`, `stop` envoie une requête
  `POST`/`PUT`/`DELETE` vers `http://<API_BASE_URL>/treatments` (header `Authorization: Bearer <JWT>`).
  Les échecs réseau sont silencieux → les données restent en local.
- **Pull** : le *pull-to-refresh* sur le tableau de bord appelle `TreatmentRepository.syncFromBackend()`
  → `GET /treatments` → upsert local (match par `user_id + medication_name + start_date`).
- **Schema backend** : `medicationId` accepte `ObjectId` **ou** `string`/`number` (compatibilité SQLite local).

### Tester la sync avec Postman / Bruno

1. **Connexion** : `POST /users/login` → récupérer le token JWT.
2. **Header** : `Authorization: Bearer <token>`
3. **Créer** : `POST /treatments` avec body :
   ```json
   {
     "medicationName": "Doliprane",
     "medicationDosage": "500 mg",
     "dose": "1 comprimé",
     "reminderTimes": ["08:00", "20:00"],
     "startDate": "2026-11-12",
     "status": "active"
   }
   ```
4. **Lister** : `GET /treatments`
5. **Pull dans l'app** : pull-to-refresh sur l'accueil → le traitement apparaît localement.

---

## Design system

Le tableau de bord suit le design exporté depuis Stitch (`MediTrack Health Manager`) :

| Rôle | Couleur |
| --- | --- |
| Primaire | `#00685D` |
| Primaire conteneur | `#008376` |
| Secondaire | `#0058BD` |
| Surface | `#F5F7FA` |
| Surface basse | `#F0F3FF` |
| Texte primaire | `#1D3557` |
| Texte secondaire | `#6C757D` |
| Alerte / erreur | `#F4A261` · `#E63946` |

- Typographie : H1 28 px / 700, H3 18 px / 600, corps 16 px, légende 13 px
- Cartes : rayon 12 px, ombre douce, badge d'icône 40 × 40 px
- Bouton principal : hauteur 52 px, rayon 12 px ; cibles tactiles ≥ 48 px
- Barre de navigation basse : 80 px — **Accueil · Traitements · Médicaments · Rendez-vous · Activité**
  (le profil s'ouvre via l'avatar de l'en-tête)

L'implémentation est centralisée dans `lib/features/auth/screens/home_screen.dart` (classes
privées `_P` pour la palette et `_T` pour la typographie).

---

## Tests et qualité

```bash
flutter analyze                  # analyse statique (lib + test)

flutter test test/appointments_test.dart   # modèles rendez-vous (9 tests)
flutter test test/features                 # activité (3) + widget (5) + traitements (40) = 48 tests
```

### Lire la sortie des tests

Le fichier `dart_test.yaml` force le reporter `expanded`, donc chaque test s'affiche :

```text
00:00 +0: AppointmentStatus Enum Tests French labels should match expected values
00:00 +1: AppointmentStatus Enum Tests fromString should handle casing and fallback safely
00:00 +2: Practitioner Model Tests Serialization toMap and fromMap
...
00:00 +9: All tests passed!
```

- `+9` = nombre de tests **réussis** ; un `-1` indiquerait un test **échoué** et le détail
  (assertion, fichier, ligne) serait affiché juste avant.
- La ligne finale ne montre que le total : c'est normal, les lignes du dessus listent le détail.
- Pour ne lancer qu'un test : `flutter test test/appointments_test.dart --plain-name "copyWith"`.
- Pour forcer le détail sans le fichier de config : `flutter test --reporter expanded`.

### Ce que les tests vérifient réellement

**Modèles (`test/appointments_test.dart`)** — 9 tests :

- sérialisation SQLite `toMap()` / `fromMap()` (dont les jointures praticien / lieu) ;
- valeurs par défaut d'une ligne incomplète (`duration_minutes` → 30, `modality` → `presentiel`, `status` → `SCHEDULED`) ;
- `copyWith()` sans mutation de l'objet d'origine ;
- libellés français et repli sûr de `AppointmentStatus.fromString()` ;
- adresse complète d'un lieu (`HealthFacility.fullAddress`) ;
- détection de téléconsultation (`isTeleconsultation`, `videoUrl`).

**Widget `AppointmentCard` (`test/features/appointments/appointment_card_test.dart`)** — 5 tests :

- affichage de la date, de la durée, du motif, du praticien, du lieu et du statut ;
- badge et lien visio pour une téléconsultation ;
- tap sur la carte → callback d'ouverture ;
- suppression **avec confirmation** (annuler ne supprime rien, confirmer appelle le callback) ;
- menu de statut → callback avec le statut choisi.

**Modèle `PhysicalActivity` (`test/features/physical_activity/physical_activity_test.dart`)** — 3 tests :
aller-retour `toMap()`/`fromMap()`, champs facultatifs nuls, `copyWith()` ciblé.

**Modèle `Treatment` (`test/features/treatments/treatment_test.dart`)** — 40 tests :

- enums, sérialisation, règles métier (`isActive`, `isChronic`, `hasExpiredDate`, `timesPerDay`), `frequencyLabel`,
  progression `TreatmentSummary`, helpers `date_fr`.

### Limites connues

Ces tests ne couvrent pas : les écrans complets (navigation de bout en bout), la base SQLite
réelle (`sqflite` n'est pas initialisé dans les tests), les appels HTTP au backend, ni la logique
métier de `AppointmentProvider.upcomingAppointments` (le provider est lié directement à
`DatabaseHelper`, sans injection possible en test). La vérification de ces parcours se fait
manuellement sur appareil.

> `test/widget_test.dart` est le test « compteur » généré par `flutter create` : il correspond à
> l'ancien template et échoue logiquement (l'application n'affiche plus de compteur). Il peut être
> supprimé sans impact.

---

## Dépannage

| Symptôme | Cause probable / solution |
| --- | --- |
| `Connection refused` / inscription impossible sur téléphone | L'APK a été construit sans `--dart-define=API_BASE_URL=…` (il pointe encore vers `10.0.2.2`) |
| Le téléphone n'atteint pas l'API | PC et téléphone pas sur le même Wi-Fi, pare-feu Windows bloquant le port 3000, ou IP du PC changée |
| Code de vérification non reçu | `SMTP_*` incorrect, mot de passe d'application manquant, e-mail en spam |
| `401` / session perdue | Token expiré : se reconnecter (l'app efface la session invalide) |
| Données de test à réinitialiser | Désinstaller l'app (efface `meditrack.db`) ou supprimer la base SQLite de l'appareil |
| Le serveur ne démarre pas | MongoDB n'est pas lancé, ou `MONGO_URI` invalide |
| Traitement non visible dans MongoDB | Vérifier `flutter run --dart-define=API_BASE_URL=…`, logs `MediTrack: sync CREATE` dans la console, token JWT valide |

---

## Auteurs

Projet **MediTrack** — dépôt : <https://github.com/rouamenaa/meditrackmobile>
