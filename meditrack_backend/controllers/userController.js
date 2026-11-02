const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

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
    const { nom, prenom, email, password, telephone, date_naissance, sexe } = req.body;
    if (!nom || !prenom || !email || !password) {
      return res.status(400).json({ error: 'Champs obligatoires manquants' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Mot de passe : 6 caractères minimum' });
    }
    if (await User.findOne({ email: email.trim().toLowerCase() })) {
      return res.status(409).json({ error: 'Cet email est déjà utilisé' });
    }
    const user = await User.create({
      nom, prenom, email, telephone, date_naissance, sexe,
      password: await bcrypt.hash(password, 10),
    });
    res.status(201).json({ token: sign(user), user });
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
    res.json({ token: sign(user), user });
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