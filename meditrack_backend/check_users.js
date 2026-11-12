const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/meditrack').then(async () => {
  const User = require('./models/User');
  const users = await User.find().select('email password nom prenom');
  console.log(users);
  process.exit(0);
});