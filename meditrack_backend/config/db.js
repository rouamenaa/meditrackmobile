const mongoose = require('mongoose');

module.exports = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connecté');
  } catch (e) {
    console.error('Erreur MongoDB :', e.message);
    process.exit(1);
  }
};