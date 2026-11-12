const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    patient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    doctor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    // Compatibilité
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    practitioner: {
      type: mongoose.Schema.Types.Mixed,
    },
    facility: {
      type: mongoose.Schema.Types.Mixed,
    },
    start_date_time: { type: Date, index: true },
    startDateTime: { type: Date },
    duration_minutes: { type: Number, default: 30 },
    durationMinutes: { type: Number, default: 30 },
    reason: { type: String, required: true, trim: true },
    notes: { type: String, default: '' },
    modality: {
      type: String,
      enum: ['presentiel', 'teleconsultation'],
      default: 'presentiel',
    },
    video_url: { type: String, default: null },
    videoUrl: { type: String, default: null },
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

// Formatage JSON propre pour l'application Flutter
appointmentSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Appointment', appointmentSchema);
