const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    patient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    doctor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    start_date_time: { type: Date, required: true, index: true },
    duration_minutes: { type: Number, required: true, default: 30 },
    reason: { type: String, required: true, trim: true },
    notes: { type: String, default: '' },
    modality: {
      type: String,
      enum: ['presentiel', 'teleconsultation'],
      default: 'presentiel',
    },
    video_url: { type: String, default: null },
    facility_name: { type: String, default: '' },
    facility_address: { type: String, default: '' },
    status: {
      type: String,
      enum: [
        'SCHEDULED',
        'CONFIRMED',
        'RESCHEDULED',
        'CANCELLED_BY_PATIENT',
        'CANCELLED_BY_PRACTITIONER',
        'COMPLETED',
        'MISSED',
      ],
      default: 'SCHEDULED',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Appointment', appointmentSchema);
