const mongoose = require('mongoose');
const Appointment = require('../models/Appointment');
const User = require('../models/User');

const DOCTOR_FIELDS =
  'nom prenom email telephone specialite rpps_adeli etablissement';

function toResponse(appointment) {
  const doctor = appointment.doctor;
  const patient = appointment.patient;
  return {
    id: appointment._id.toString(),
    doctor_user_id: doctor?._id?.toString() || appointment.doctor?.toString(),
    doctor: doctor && typeof doctor === 'object' && doctor.nom
      ? {
          id: doctor._id.toString(),
          nom: doctor.nom,
          prenom: doctor.prenom,
          email: doctor.email,
          telephone: doctor.telephone,
          specialite: doctor.specialite,
          rpps_adeli: doctor.rpps_adeli,
          etablissement: doctor.etablissement,
        }
      : appointment.practitioner || null,
    patient_id: patient?._id?.toString() || appointment.patient?.toString() || appointment.userId?.toString(),
    patient_name:
      patient && typeof patient === 'object' && patient.nom
        ? `${patient.prenom} ${patient.nom}`.trim()
        : '',
    start_date_time: (appointment.start_date_time || appointment.startDateTime || new Date()).toISOString(),
    startDateTime: appointment.startDateTime || appointment.start_date_time,
    duration_minutes: appointment.duration_minutes || appointment.durationMinutes || 30,
    durationMinutes: appointment.durationMinutes || appointment.duration_minutes || 30,
    reason: appointment.reason,
    notes: appointment.notes,
    modality: appointment.modality,
    video_url: appointment.video_url || appointment.videoUrl,
    videoUrl: appointment.videoUrl || appointment.video_url,
    facility_name: appointment.facility_name,
    facility_address: appointment.facility_address,
    facility: appointment.facility,
    practitioner: appointment.practitioner,
    status: appointment.status,
  };
}

function populated(query) {
  return query
    .populate('doctor', DOCTOR_FIELDS)
    .populate('patient', 'nom prenom');
}

// GET /appointments
exports.listMine = async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('role');
    const filter = user?.role === 'medecin'
      ? { $or: [{ doctor: req.userId }, { userId: req.userId }] }
      : { $or: [{ patient: req.userId }, { userId: req.userId }] };

    const appointments = await populated(
      Appointment.find(filter).sort({ start_date_time: 1, startDateTime: 1 })
    );
    res.json(appointments.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// GET par ID
exports.getAppointmentById = async (req, res) => {
  try {
    const id = req.params.appointmentId || req.params.id;
    const appointment = await populated(Appointment.findById(id));
    if (!appointment) return res.status(404).json({ error: 'Rendez-vous introuvable' });
    res.json(toResponse(appointment));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /appointments
exports.create = async (req, res) => {
  try {
    const {
      doctor_user_id,
      practitioner,
      facility,
      start_date_time,
      startDateTime,
      duration_minutes,
      durationMinutes,
      reason,
      notes,
      modality,
      video_url,
      videoUrl,
      facility_name,
      facility_address,
      status,
    } = req.body;

    const start = new Date(start_date_time || startDateTime);
    const duration = Number(duration_minutes || durationMinutes || 30);
    const visitMode = modality === 'teleconsultation' ? 'teleconsultation' : 'presentiel';

    let doctorId = null;
    if (doctor_user_id && mongoose.isValidObjectId(doctor_user_id)) {
      doctorId = doctor_user_id;
    }

    const appointment = await Appointment.create({
      patient: req.userId,
      userId: req.userId,
      doctor: doctorId,
      practitioner: practitioner || null,
      facility: facility || null,
      start_date_time: start,
      startDateTime: start,
      duration_minutes: duration,
      durationMinutes: duration,
      reason: String(reason || '').trim(),
      notes: notes == null ? '' : String(notes).trim(),
      modality: visitMode,
      video_url: video_url || videoUrl || null,
      videoUrl: videoUrl || video_url || null,
      facility_name: facility_name || facility?.name || '',
      facility_address: facility_address || facility?.address || '',
      status: status || 'SCHEDULED',
    });

    const result = await populated(Appointment.findById(appointment._id));
    res.status(201).json(toResponse(result));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// PUT /appointments/:appointmentId
exports.update = async (req, res) => {
  try {
    const id = req.params.appointmentId || req.params.id;
    const appointment = await Appointment.findById(id);
    if (!appointment) return res.status(404).json({ error: 'Rendez-vous introuvable' });

    Object.assign(appointment, req.body);
    if (req.body.start_date_time || req.body.startDateTime) {
      const d = new Date(req.body.start_date_time || req.body.startDateTime);
      appointment.start_date_time = d;
      appointment.startDateTime = d;
    }
    if (req.body.facility !== undefined) {
      appointment.facility = req.body.facility;
      appointment.markModified('facility');
    }
    if (req.body.facility_name !== undefined) {
      appointment.facility_name = req.body.facility_name;
    }
    if (req.body.facility_address !== undefined) {
      appointment.facility_address = req.body.facility_address;
    }

    await appointment.save();
    const result = await populated(Appointment.findById(appointment._id));
    res.json(toResponse(result));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// DELETE /appointments/:appointmentId
exports.remove = async (req, res) => {
  try {
    const id = req.params.appointmentId || req.params.id;
    const appointment = await Appointment.findById(id);
    if (!appointment) return res.status(404).json({ error: 'Rendez-vous introuvable' });
    await appointment.deleteOne();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Aliases pour rétrocompatibilité
exports.getAppointments = exports.listMine;
exports.createAppointment = exports.create;
exports.updateAppointment = exports.update;
exports.deleteAppointment = exports.remove;
exports.updateStatus = exports.update;
