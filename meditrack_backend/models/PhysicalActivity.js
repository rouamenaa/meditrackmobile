const mongoose = require('mongoose');

const physicalActivitySchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    durationMinutes: {
      type: Number,
      required: true,
      min: 1,
    },
    distanceKm: {
      type: Number,
      default: null,
    },
    intensity: {
      type: String,
      required: true,
      trim: true,
    },
    activityDate: {
      type: Date,
      required: true,
      index: true,
    },
    notes: {
      type: String,
      default: null,
      trim: true,
    },
    caloriesBurned: {
      type: Number,
      default: null,
    },
    localId: {
      type: Number,
      default: null,
    },
  },
  { timestamps: true }
);

physicalActivitySchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('PhysicalActivity', physicalActivitySchema);
