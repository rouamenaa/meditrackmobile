require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const connectDB = require('./config/db');

const app = express();

app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/users', require('./routes/userRoutes'));
app.use('/appointments', require('./routes/appointmentRoutes'));
app.use('/ai', require('./routes/aiRoutes'));

const PORT = process.env.PORT || 3000;

connectDB().then(() => {
  app.listen(PORT, '0.0.0.0', () =>
    console.log(`MediTrack API sur http://localhost:${PORT}`)
  );
});
