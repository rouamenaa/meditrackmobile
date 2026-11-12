const Treatment = require('../models/Treatment');

function toResponse(t) {
  return {
    id: t.id,
    medicationId: t.medicationId?.toString() || null,
    medicationName: t.medicationName,
    medicationDosage: t.medicationDosage,
    dose: t.dose,
    reminderTimes: t.reminderTimes,
    startDate: t.startDate.toISOString().split('T')[0],
    endDate: t.endDate ? t.endDate.toISOString().split('T')[0] : null,
    status: t.status,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  };
}

exports.listMine = async (req, res) => {
  try {
    const treatments = await Treatment.find({ user: req.userId })
      .sort({ startDate: 1, createdAt: -1 });
    res.json(treatments.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.getById = async (req, res) => {
  try {
    const t = await Treatment.findOne({ _id: req.params.id, user: req.userId });
    if (!t) return res.status(404).json({ error: 'Traitement introuvable' });
    res.json(toResponse(t));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.create = async (req, res) => {
  try {
    console.log('POST /treatments body:', JSON.stringify(req.body));
    const {
      medicationId,
      medicationName,
      medicationDosage,
      dose,
      reminderTimes,
      startDate,
      endDate,
      status,
    } = req.body;

    if (!medicationName || !dose || !reminderTimes || !startDate) {
      return res.status(400).json({ error: 'Champs obligatoires manquants' });
    }

    const t = await Treatment.create({
      user: req.userId,
      medicationId: medicationId || null,
      medicationName,
      medicationDosage: medicationDosage || '',
      dose,
      reminderTimes: Array.isArray(reminderTimes) ? reminderTimes : [reminderTimes],
      startDate: new Date(startDate),
      endDate: endDate ? new Date(endDate) : null,
      status: status || 'active',
    });
    res.status(201).json(toResponse(t));
  } catch (e) {
    console.error('POST /treatments error:', e);
    res.status(500).json({ error: e.message });
  }
};

exports.update = async (req, res) => {
  try {
    const {
      medicationId,
      medicationName,
      medicationDosage,
      dose,
      reminderTimes,
      startDate,
      endDate,
      status,
    } = req.body;

    const updates = {};
    if (medicationId !== undefined) updates.medicationId = medicationId || null;
    if (medicationName !== undefined) updates.medicationName = medicationName;
    if (medicationDosage !== undefined) updates.medicationDosage = medicationDosage;
    if (dose !== undefined) updates.dose = dose;
    if (reminderTimes !== undefined) updates.reminderTimes = Array.isArray(reminderTimes) ? reminderTimes : [reminderTimes];
    if (startDate !== undefined) updates.startDate = new Date(startDate);
    if (endDate !== undefined) updates.endDate = endDate ? new Date(endDate) : null;
    if (status !== undefined) updates.status = status;

    const t = await Treatment.findOneAndUpdate(
      { _id: req.params.id, user: req.userId },
      updates,
      { new: true, runValidators: true }
    );
    if (!t) return res.status(404).json({ error: 'Traitement introuvable' });
    res.json(toResponse(t));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.remove = async (req, res) => {
  try {
    const t = await Treatment.findOneAndDelete({ _id: req.params.id, user: req.userId });
    if (!t) return res.status(404).json({ error: 'Traitement introuvable' });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};