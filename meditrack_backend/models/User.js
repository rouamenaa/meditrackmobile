const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    nom: { type: String, required: true, trim: true },
    prenom: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true }, 
    role: { type: String, enum: ['patient', 'medecin'], default: 'patient' },

    email_verifie: Boolean,
    verification_code: String,
    verification_expires: Date,

    reset_code: String,
    reset_expires: Date,

    telephone: String,
    date_naissance: String,
    sexe: String, 

    notif_medicaments: { type: Boolean, default: true },
    notif_rdv: { type: Boolean, default: true },
    notif_son: { type: Boolean, default: true },
    notif_vibration: { type: Boolean, default: true },
    rappel_avant_minutes: { type: Number, default: 10 },

    photo: String, 
    groupe_sanguin: String,
    condition_medicale: String,
    contact_urgence_nom: String,
    contact_urgence_lien: String,
    contact_urgence_tel: String,
    assurance_nom: String,
    assurance_police: String,

    specialite: String,
    rpps_adeli: String,
    etablissement: String,
    horaires_consultation: String,

    medecins: [
      {
        nom: { type: String, required: true },
        specialite: { type: String, required: true },
      },
    ],
  },
  { timestamps: true }
);

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