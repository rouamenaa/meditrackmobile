const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  const token = (req.headers.authorization || '').replace('Bearer ', '');
  try {
    req.userId = jwt.verify(token, process.env.JWT_SECRET).id;
  } catch (e) {
    return res.status(401).json({ error: 'Token invalide ou absent' });
  }
  // Un utilisateur ne peut accéder qu'à son propre compte
  if (req.params.id && req.params.id !== req.userId) {
    return res.status(403).json({ error: 'Accès refusé' });
  }
  next();
};