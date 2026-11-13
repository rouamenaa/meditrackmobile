const PhysicalActivity = require('../models/PhysicalActivity');

function toResponse(a) {
  return {
    id: a.id || a._id.toString(),
    userId: a.user ? a.user.toString() : null,
    type: a.type,
    durationMinutes: a.durationMinutes,
    distanceKm: a.distanceKm,
    intensity: a.intensity,
    activityDate: a.activityDate ? a.activityDate.toISOString() : null,
    notes: a.notes,
    caloriesBurned: a.caloriesBurned,
    localId: a.localId,
    createdAt: a.createdAt,
    updatedAt: a.updatedAt,
  };
}

// GET /activities
exports.listMine = async (req, res) => {
  try {
    const activities = await PhysicalActivity.find({ user: req.userId })
      .sort({ activityDate: -1, createdAt: -1 });
    res.json(activities.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// GET /activities/:id
exports.getById = async (req, res) => {
  try {
    const a = await PhysicalActivity.findOne({ _id: req.params.id, user: req.userId });
    if (!a) return res.status(404).json({ error: 'Activité introuvable' });
    res.json(toResponse(a));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /activities
exports.create = async (req, res) => {
  try {
    const {
      type,
      durationMinutes,
      distanceKm,
      intensity,
      activityDate,
      notes,
      caloriesBurned,
      localId,
    } = req.body;

    if (!type || durationMinutes == null || !intensity || !activityDate) {
      return res.status(400).json({ error: 'Champs obligatoires manquants' });
    }

    const activity = await PhysicalActivity.create({
      user: req.userId,
      type: type.trim(),
      durationMinutes: Number(durationMinutes),
      distanceKm: distanceKm != null ? Number(distanceKm) : null,
      intensity: intensity.trim(),
      activityDate: new Date(activityDate),
      notes: notes != null && notes.trim() !== '' ? notes.trim() : null,
      caloriesBurned: caloriesBurned != null ? Number(caloriesBurned) : null,
      localId: localId != null ? Number(localId) : null,
    });

    res.status(201).json(toResponse(activity));
  } catch (e) {
    console.error('POST /activities error:', e);
    res.status(500).json({ error: e.message });
  }
};

// PUT /activities/:id
exports.update = async (req, res) => {
  try {
    const {
      type,
      durationMinutes,
      distanceKm,
      intensity,
      activityDate,
      notes,
      caloriesBurned,
      localId,
    } = req.body;

    const updates = {};
    if (type !== undefined) updates.type = type.trim();
    if (durationMinutes !== undefined) updates.durationMinutes = Number(durationMinutes);
    if (distanceKm !== undefined) updates.distanceKm = distanceKm != null ? Number(distanceKm) : null;
    if (intensity !== undefined) updates.intensity = intensity.trim();
    if (activityDate !== undefined) updates.activityDate = new Date(activityDate);
    if (notes !== undefined) updates.notes = notes != null && notes.trim() !== '' ? notes.trim() : null;
    if (caloriesBurned !== undefined) updates.caloriesBurned = caloriesBurned != null ? Number(caloriesBurned) : null;
    if (localId !== undefined) updates.localId = localId != null ? Number(localId) : null;

    const a = await PhysicalActivity.findOneAndUpdate(
      { _id: req.params.id, user: req.userId },
      updates,
      { returnDocument: 'after', runValidators: true }
    );

    if (!a) return res.status(404).json({ error: 'Activité introuvable' });
    res.json(toResponse(a));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// DELETE /activities/:id
exports.remove = async (req, res) => {
  try {
    const a = await PhysicalActivity.findOneAndDelete({ _id: req.params.id, user: req.userId });
    if (!a) return res.status(404).json({ error: 'Activité introuvable' });
    res.json({ ok: true, id: req.params.id });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /activities/sync
exports.syncBatch = async (req, res) => {
  try {
    const { activities } = req.body;
    if (!Array.isArray(activities)) {
      return res.status(400).json({ error: 'Le champ activities doit être un tableau' });
    }

    const results = [];
    for (const item of activities) {
      if (!item.type || item.durationMinutes == null || !item.intensity || !item.activityDate) {
        continue;
      }

      const itemDate = new Date(item.activityDate);
      let doc = null;

      // 1. Chercher par remoteId s'il est déjà fourni
      if (item.remoteId || item.id) {
        const idToSearch = item.remoteId || item.id;
        if (typeof idToSearch === 'string' && idToSearch.length === 24) {
          doc = await PhysicalActivity.findOne({ _id: idToSearch, user: req.userId });
        }
      }

      // 2. Déduplication : si même date, même type et même durée pour ce même user
      if (!doc) {
        doc = await PhysicalActivity.findOne({
          user: req.userId,
          type: item.type.trim(),
          activityDate: itemDate,
          durationMinutes: Number(item.durationMinutes),
        });
      }

      if (doc) {
        // Mise à jour de l'existant
        doc.distanceKm = item.distanceKm != null ? Number(item.distanceKm) : doc.distanceKm;
        doc.intensity = item.intensity.trim();
        doc.notes = item.notes != null ? item.notes.trim() : doc.notes;
        doc.caloriesBurned = item.caloriesBurned != null ? Number(item.caloriesBurned) : doc.caloriesBurned;
        if (item.localId != null) doc.localId = Number(item.localId);
        await doc.save();
      } else {
        // Création d'une nouvelle entrée
        doc = await PhysicalActivity.create({
          user: req.userId,
          type: item.type.trim(),
          durationMinutes: Number(item.durationMinutes),
          distanceKm: item.distanceKm != null ? Number(item.distanceKm) : null,
          intensity: item.intensity.trim(),
          activityDate: itemDate,
          notes: item.notes != null && item.notes.trim() !== '' ? item.notes.trim() : null,
          caloriesBurned: item.caloriesBurned != null ? Number(item.caloriesBurned) : null,
          localId: item.localId != null ? Number(item.localId) : null,
        });
      }

      results.push({
        localId: item.localId ?? (typeof item.id === 'number' ? item.id : null),
        remoteId: doc._id.toString(),
        activity: toResponse(doc),
      });
    }

    res.json({ synced: results });
  } catch (e) {
    console.error('POST /activities/sync error:', e);
    res.status(500).json({ error: e.message });
  }
};
