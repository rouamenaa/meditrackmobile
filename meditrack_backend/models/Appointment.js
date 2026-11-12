const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    practitioner: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },
    facility: {
      type: mongoose.Schema.Types.Mixed,
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
      default: 'presentiel',
    },
    videoUrl: String,
    status: {
      type: String,
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
