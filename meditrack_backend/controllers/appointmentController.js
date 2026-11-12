const Appointment = require('../models/Appointment');

// GET /appointments : Récupère tous les rendez-vous de l'utilisateur connecté
exports.getAppointments = async (req, res) => {
  try {
    const appointments = await Appointment.find({ userId: req.user.id }).sort({
      startDateTime: 1,
    });
    res.json(appointments);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// GET /appointments/:id : Récupère un rendez-vous par son ID
exports.getAppointmentById = async (req, res) => {
  try {
    const appointment = await Appointment.findOne({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!appointment) {
      return res.status(404).json({ error: 'Rendez-vous introuvable' });
    }
    res.json(appointment);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /appointments : Crée un nouveau rendez-vous
exports.createAppointment = async (req, res) => {
  try {
    const {
      practitioner,
      facility,
      startDateTime,
      durationMinutes,
      reason,
      notes,
      modality,
      videoUrl,
      status,
    } = req.body;

    if (!reason || !startDateTime || !practitioner) {
      return res.status(400).json({ error: 'Champs obligatoires manquants' });
    }

    const appointment = await Appointment.create({
      userId: req.user.id,
      practitioner,
      facility,
      startDateTime: new Date(startDateTime),
      durationMinutes: durationMinutes || 30,
      reason,
      notes,
      modality: modality || 'presentiel',
      videoUrl,
      status: status || 'SCHEDULED',
    });

    res.status(201).json(appointment);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// PUT /appointments/:id : Met à jour un rendez-vous
exports.updateAppointment = async (req, res) => {
  try {
    const updateData = { ...req.body };
    if (updateData.startDateTime) {
      updateData.startDateTime = new Date(updateData.startDateTime);
    }

    const appointment = await Appointment.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      updateData,
      { new: true, runValidators: true }
    );

    if (!appointment) {
      return res.status(404).json({ error: 'Rendez-vous introuvable' });
    }

    res.json(appointment);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// PATCH /appointments/:id/status : Met à jour uniquement le statut
exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!status) {
      return res.status(400).json({ error: 'Statut manquant' });
    }

    const appointment = await Appointment.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { status },
      { new: true }
    );

    if (!appointment) {
      return res.status(404).json({ error: 'Rendez-vous introuvable' });
    }

    res.json(appointment);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// DELETE /appointments/:id : Supprime un rendez-vous
exports.deleteAppointment = async (req, res) => {
  try {
    const result = await Appointment.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });

    if (!result) {
      return res.status(404).json({ error: 'Rendez-vous introuvable' });
    }

    res.json({ ok: true, message: 'Rendez-vous supprimé avec succès' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

