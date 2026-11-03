const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    nom: { type: String, required: true, trim: true },
    prenom: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true }, // haché avec bcrypt

    // Rôle : patient (par défaut) ou médecin
    role: { type: String, enum: ['patient', 'medecin'], default: 'patient' },

    // Vérification de l'adresse email
    // Pas de default : les comptes créés avant cette fonctionnalité restent valides.
    email_verifie: Boolean,
    verification_code: String,
    verification_expires: Date,

    // Réinitialisation du mot de passe
    reset_code: String,
    reset_expires: Date,

    telephone: String,
    date_naissance: String, // "1987-04-14"
    sexe: String,

    notif_medicaments: { type: Boolean, default: true },
    notif_rdv: { type: Boolean, default: true },
    notif_son: { type: Boolean, default: true },
    notif_vibration: { type: Boolean, default: true },
    rappel_avant_minutes: { type: Number, default: 10 },

    photo: String, // ex: "uploads/1712345678-123.jpg"
    groupe_sanguin: String,
    condition_medicale: String,
    contact_urgence_nom: String,
    contact_urgence_lien: String,
    contact_urgence_tel: String,
    assurance_nom: String,
    assurance_police: String,

    medecins: [
      {
        nom: { type: String, required: true },
        specialite: { type: String, required: true },
      },
    ],
  },
  { timestamps: true }
);

// On ne renvoie jamais le mot de passe, et _id devient id
userSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    if (ret.medecins) {
      ret.medecins = ret.medecins.map((m) => {
        m.id = m._id.toString();
        delete m._id;
        return m;
      });
    }
    delete ret._id;
    delete ret.__v;
    delete ret.password;
    delete ret.verification_code;
    delete ret.verification_expires;
    delete ret.reset_code;
    delete ret.reset_expires;
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);