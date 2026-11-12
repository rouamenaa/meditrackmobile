const mongoose = require('mongoose');

const treatmentSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    medicationId: {
      type: mongoose.Schema.Types.Mixed, // accept ObjectId or string (from local SQLite)
      required: false,
      index: true,
    },
    medicationName: { type: String, required: true, trim: true },
    medicationDosage: { type: String, default: '' },
    dose: { type: String, required: true, trim: true },
    reminderTimes: { type: [String], required: true, default: ['08:00'] },
    startDate: { type: Date, required: true, index: true },
    endDate: { type: Date, default: null, index: true },
    status: {
      type: String,
      enum: ['planned', 'active', 'stopped', 'completed'],
      default: 'active',
      index: true,
    },
  },
  { timestamps: true }
);

treatmentSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Treatment', treatmentSchema);