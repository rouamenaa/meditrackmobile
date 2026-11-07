// Émulateur Android : 10.0.2.2 = ton PC.
// Vrai téléphone : l'IP de ton PC sur le Wi-Fi, ex. 'http://192.168.1.20:3000'
// Pour un vrai téléphone, on surcharge sans modifier ce fichier :
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
// (sans surcharge, on garde 10.0.2.2 pour l'émulateur)
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);