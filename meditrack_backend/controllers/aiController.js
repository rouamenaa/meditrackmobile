// Assistant santé IA du module user (Google Gemini).
// Route protégée : un utilisateur connecté discute avec "MediTrack AI".

const User = require('../models/User');
const { generateReply } = require('../config/gemini');

const MAX_MESSAGES = 20; // borne l'historique envoyé au modèle
const MAX_CHARS = 4000; // borne la taille d'un message

// Consignes système : cadre l'assistant (santé générale, pas de diagnostic).
function buildSystemInstruction(user) {
  const facts = [];
  if (user && user.prenom) facts.push(`First name: ${user.prenom}.`);
  if (user && user.date_naissance) facts.push(`Date of birth: ${user.date_naissance}.`);
  if (user && user.sexe) facts.push(`Sex: ${user.sexe}.`);
  if (user && user.groupe_sanguin) facts.push(`Blood group: ${user.groupe_sanguin}.`);
  if (user && user.condition_medicale) {
    facts.push(`Known medical condition(s): ${user.condition_medicale}.`);
  }

  return [
    'You are "MediTrack AI", a friendly and careful health assistant inside the MediTrack app.',
    'Always answer in English, with clear language and short paragraphs (2-5 sentences unless more detail is requested).',
    'Give general, evidence-based health information only.',
    'Never give a definitive diagnosis and never prescribe medication or dosages.',
    'Always encourage the user to consult a qualified healthcare professional for medical decisions.',
    'If the user describes a possible emergency (chest pain, trouble breathing, severe bleeding, fainting, suicidal thoughts), tell them to contact emergency services immediately.',
    ...(facts.length ? ['Context about this user:', ...facts] : []),
  ].join(' ');
}

// Nettoie et valide l'historique reçu du client.
function sanitizeMessages(raw) {
  if (!Array.isArray(raw)) return [];
  const clean = raw
    .filter((m) => m && typeof m.text === 'string' && m.text.trim())
    .map((m) => ({
      role: m.role === 'model' ? 'model' : 'user',
      text: String(m.text).slice(0, MAX_CHARS),
    }));
  // Gemini exige que la conversation commence par un tour utilisateur.
  const firstUser = clean.findIndex((m) => m.role === 'user');
  const start = firstUser === -1 ? clean.length : firstUser;
  return clean.slice(start).slice(-MAX_MESSAGES);
}

// POST /ai/chat  { messages: [{ role: 'user'|'model', text }] }
exports.chat = async (req, res) => {
  try {
    const messages = sanitizeMessages(req.body && req.body.messages);
    if (messages.length === 0) {
      return res.status(400).json({ error: 'messages must be a non-empty array' });
    }
    if (messages[messages.length - 1].role !== 'user') {
      return res.status(400).json({ error: 'The last message must come from the user' });
    }

    // Contexte du profil (facultatif : l'assistant fonctionne même sans).
    const user = req.userId ? await User.findById(req.userId).catch(() => null) : null;

    const reply = await generateReply({
      systemInstruction: buildSystemInstruction(user || {}),
      messages,
    });

    res.json({ reply });
  } catch (e) {
    if (e.code === 'NO_API_KEY') {
      return res.status(503).json({
        error: 'The AI assistant is not configured yet (GEMINI_API_KEY missing).',
      });
    }
    res.status(502).json({ error: e.message });
  }
};
