const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    practitioner: {
      id: Number,
      lastName: { type: String, required: true },
      firstName: { type: String, required: true },
      title: { type: String, default: 'Dr' },
      specialty: { type: String, required: true },
      phone: String,
      email: String,
      rppsAdeli: String,
    },
    facility: {
      id: Number,
      name: String,
      type: String,
      address: String,
      buildingFloor: String,
      latitude: Number,
      longitude: Number,
    },
    startDateTime: {
      type: Date,
      required: true,
    },
    durationMinutes: {
      type: Number,
      default: 30,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
    },
    notes: {
      type: String,
      trim: true,
    },
    modality: {
      type: String,
      enum: ['presentiel', 'teleconsultation'],
      default: 'presentiel',
    },
    videoUrl: String,
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

