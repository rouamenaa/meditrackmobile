// Appel de l'API Google Gemini (génération de contenu) via REST + fetch natif.
// La clé est lue dans .env -> GEMINI_API_KEY ; le modèle dans GEMINI_MODEL.

const DEFAULT_MODEL = 'gemini-3.1-flash-lite';
const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

// Convertit l'historique [{ role: 'user'|'model', text }] au format Gemini.
function toGeminiContents(messages) {
  return messages
    .filter((m) => m && typeof m.text === 'string' && m.text.trim())
    .map((m) => ({
      role: m.role === 'model' ? 'model' : 'user',
      parts: [{ text: m.text }],
    }));
}

/**
 * Envoie une conversation à Gemini et renvoie le texte de la réponse.
 * @param {{ systemInstruction?: string, messages: Array<{role:string,text:string}> }} opts
 * @returns {Promise<string>}
 */
async function generateReply({ systemInstruction, messages }) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    const err = new Error(
      'AI assistant not configured: set GEMINI_API_KEY in .env'
    );
    err.code = 'NO_API_KEY';
    throw err;
  }

  const model = process.env.GEMINI_MODEL || DEFAULT_MODEL;
  const url = `${API_BASE}/${model}:generateContent?key=${apiKey}`;

  const body = {
    contents: toGeminiContents(messages),
    generationConfig: { temperature: 0.6, maxOutputTokens: 1024 },
  };
  if (systemInstruction) {
    body.system_instruction = { parts: [{ text: systemInstruction }] };
  }

  let res;
  try {
    res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(40000),
    });
  } catch (e) {
    const timedOut = e.name === 'TimeoutError' || e.name === 'AbortError';
    const err = new Error(
      timedOut
        ? 'The AI service timed out. Please try again.'
        : 'Unable to reach the AI service'
    );
    err.code = timedOut ? 'AI_TIMEOUT' : 'NETWORK';
    throw err;
  }

  const data = await res.json().catch(() => null);
  if (!res.ok) {
    const msg =
      (data && data.error && data.error.message) ||
      `AI service error ${res.status}`;
    const err = new Error(msg);
    err.code = 'GEMINI_ERROR';
    err.status = res.status;
    throw err;
  }

  const candidate = data && data.candidates && data.candidates[0];
  const text =
    candidate && candidate.content && Array.isArray(candidate.content.parts)
      ? candidate.content.parts.map((p) => p.text || '').join('')
      : '';

  if (!text.trim()) {
    const err = new Error('Empty response from the AI model');
    err.code = 'EMPTY_RESPONSE';
    throw err;
  }
  return text.trim();
}

module.exports = { generateReply, DEFAULT_MODEL };
