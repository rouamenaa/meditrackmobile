const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendMail, generateCode } = require('../config/mailer');

const CODE_TTL_MS = 15 * 60 * 1000; // 15 minutes

const sign = (user) =>
  jwt.sign({ id: user._id.toString() }, process.env.JWT_SECRET, { expiresIn: '30d' });

// Champs modifiables avec PUT
const EDITABLE = [
  'nom', 'prenom', 'telephone', 'date_naissance', 'sexe',
  'notif_medicaments', 'notif_rdv', 'notif_son', 'notif_vibration',
  'rappel_avant_minutes', 'groupe_sanguin', 'condition_medicale',
  'contact_urgence_nom', 'contact_urgence_lien', 'contact_urgence_tel',
  'assurance_nom', 'assurance_police',
];

// Envoie un code de vérification. Renvoie un message d'erreur, ou null si OK.
async function sendVerificationCode(user) {
  const code = generateCode();
  user.verification_code = code;
  user.verification_expires = new Date(Date.now() + CODE_TTL_MS);
  await user.save();
  try {
    await sendMail({
      to: user.email,
      subject: 'MediTrack – Vérification de votre compte',
      text: `Bonjour ${user.prenom}, votre code de vérification MediTrack est : ${code} (valable 15 minutes).`,
      html: `<p>Bonjour ${user.prenom},</p>
<p>Votre code de vérification MediTrack est :</p>
<p style="font-size:24px;font-weight:bold;letter-spacing:4px">${code}</p>
<p>Ce code est valable 15 minutes.</p>`,
    });
    return null;
  } catch (e) {
    return e.message;
  }
}


// GET /users
exports.getUsers = async (req, res) => {
  try {
    res.json(await User.find());
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /users  (inscription)
exports.register = async (req, res) => {
  try {
    const { nom, prenom, email, password, telephone, date_naissance, sexe, role } = req.body;
    if (!nom || !prenom || !email || !password) {
      return res.status(400).json({ error: 'Champs obligatoires manquants' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Mot de passe : 6 caractères minimum' });
    }
    const safeRole = role === 'medecin' ? 'medecin' : 'patient';
    if (await User.findOne({ email: email.trim().toLowerCase() })) {
      return res.status(409).json({ error: 'Cet email est déjà utilisé' });
    }
    const user = await User.create({
      nom, prenom, email, telephone, date_naissance, sexe, role: safeRole,
      password: await bcrypt.hash(password, 10),
      email_verifie: false,
    });

    // Envoi du code de vérification (le compte existe même si l'email échoue)
    const emailError = await sendVerificationCode(user);

    res.status(201).json({
      token: sign(user),
      user,
      email_envoye: !emailError,
      ...(emailError ? { email_error: emailError } : {}),
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /users/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email: (email || '').trim().toLowerCase() });
    if (!user || !(await bcrypt.compare(password || '', user.password))) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }
    // Comptes créés avant l'ajout de la vérification (email_verifie absent) : on laisse passer
    if (user.email_verifie === false) {
      return res.status(403).json({
        error: 'Votre compte n\'est pas encore vérifié. Saisissez le code reçu par email.',
        needs_verification: true,
        email: user.email,
      });
    }
    res.json({ token: sign(user), user });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /users/verify/send  (renvoyer un code de vérification)
exports.sendVerification = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    if (!email) return res.status(400).json({ error: 'Email obligatoire' });
    const user = await User.findOne({ email });
    // On ne révèle pas l'existence du compte
    if (!user || user.email_verifie === true) return res.json({ ok: true });

    const emailError = await sendVerificationCode(user);
    if (emailError) return res.status(502).json({ error: emailError });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /users/verify/confirm  { email, code }
exports.confirmVerification = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const { code } = req.body;
    const user = await User.findOne({ email });
    if (
      !user ||
      !user.verification_code ||
      user.verification_code !== String(code || '').trim() ||
      !user.verification_expires ||
      user.verification_expires.getTime() < Date.now()
    ) {
      return res.status(400).json({ error: 'Code invalide ou expiré' });
    }
    user.email_verifie = true;
    user.verification_code = undefined;
    user.verification_expires = undefined;
    await user.save();
    res.json({ token: sign(user), user });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /users/forgot-password  { email }
exports.forgotPassword = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    if (!email) return res.status(400).json({ error: 'Email obligatoire' });
    const user = await User.findOne({ email });
    // On ne révèle pas l'existence du compte
    if (!user) return res.json({ ok: true });

    const code = generateCode();
    user.reset_code = code;
    user.reset_expires = new Date(Date.now() + CODE_TTL_MS);
    await user.save();

    try {
      await sendMail({
        to: user.email,
        subject: 'MediTrack – Réinitialisation de votre mot de passe',
        text: `Bonjour ${user.prenom}, votre code de réinitialisation MediTrack est : ${code} (valable 15 minutes).`,
        html: `<p>Bonjour ${user.prenom},</p>
<p>Votre code de réinitialisation MediTrack est :</p>
<p style="font-size:24px;font-weight:bold;letter-spacing:4px">${code}</p>
<p>Ce code est valable 15 minutes.</p>`,
      });
    } catch (e) {
      return res.status(502).json({ error: e.message });
    }
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /users/reset-password  { email, code, new_password }
exports.resetPassword = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const { code, new_password } = req.body;
    if (!new_password || new_password.length < 6) {
      return res.status(400).json({ error: 'Mot de passe : 6 caractères minimum' });
    }
    const user = await User.findOne({ email });
    if (
      !user ||
      !user.reset_code ||
      user.reset_code !== String(code || '').trim() ||
      !user.reset_expires ||
      user.reset_expires.getTime() < Date.now()
    ) {
      return res.status(400).json({ error: 'Code invalide ou expiré' });
    }
    user.password = await bcrypt.hash(new_password, 10);
    user.reset_code = undefined;
    user.reset_expires = undefined;
    user.email_verifie = true; // l'accès à l'email est prouvé
    await user.save();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// GET /users/:id
exports.getUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'Utilisateur introuvable' });
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// PUT /users/:id
exports.updateUser = async (req, res) => {
  try {
    const changes = {};
    for (const f of EDITABLE) if (f in req.body) changes[f] = req.body[f];
    const user = await User.findByIdAndUpdate(req.params.id, changes, {
      new: true,
      runValidators: true,
    });
    if (!user) return res.status(404).json({ error: 'Utilisateur introuvable' });
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// PUT /users/:id/password
exports.changePassword = async (req, res) => {
  try {
    const { old_password, new_password } = req.body;
    const user = await User.findById(req.params.id);
    if (!user || !(await bcrypt.compare(old_password || '', user.password))) {
      return res.status(401).json({ error: 'Ancien mot de passe incorrect' });
    }
    if (!new_password || new_password.length < 6) {
      return res.status(400).json({ error: 'Nouveau mot de passe trop court' });
    }
    user.password = await bcrypt.hash(new_password, 10);
    await user.save();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /users/:id/photo  (form-data, champ "image")
exports.uploadPhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Image manquante (jpeg, png ou webp, 5 Mo max)' });
    }
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { photo: `uploads/${req.file.filename}` },
      { new: true }
    );
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// DELETE /users/:id
exports.deleteUser = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// ---------- Médecins ----------
exports.getMedecins = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    res.json(user ? user.toJSON().medecins : []);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.addMedecin = async (req, res) => {
  try {
    const { nom, specialite } = req.body;
    if (!nom || !specialite) {
      return res.status(400).json({ error: 'Nom et spécialité obligatoires' });
    }
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'Utilisateur introuvable' });
    user.medecins.push({ nom, specialite });
    await user.save();
    const meds = user.toJSON().medecins;
    res.status(201).json(meds[meds.length - 1]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.deleteMedecin = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'Utilisateur introuvable' });
    user.medecins.pull(req.params.medId);
    await user.save();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};