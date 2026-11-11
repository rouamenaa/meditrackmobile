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
      : null,
    patient_id: patient?._id?.toString() || appointment.patient?.toString(),
    patient_name:
      patient && typeof patient === 'object' && patient.nom
        ? `${patient.prenom} ${patient.nom}`.trim()
        : '',
    start_date_time: appointment.start_date_time.toISOString(),
    duration_minutes: appointment.duration_minutes,
    reason: appointment.reason,
    notes: appointment.notes,
    modality: appointment.modality,
    video_url: appointment.video_url,
    facility_name: appointment.facility_name,
    facility_address: appointment.facility_address,
    status: appointment.status,
  };
}

function populated(query) {
  return query
    .populate('doctor', DOCTOR_FIELDS)
    .populate('patient', 'nom prenom');
}

exports.listMine = async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('role');
    if (!user) return res.status(404).json({ error: 'Utilisateur introuvable' });

    const filter =
      user.role === 'medecin'
        ? { doctor: req.userId }
        : { patient: req.userId };
    const appointments = await populated(
      Appointment.find(filter).sort({ start_date_time: 1 })
    );
    res.json(appointments.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.create = async (req, res) => {
  try {
    const patient = await User.findById(req.userId).select('role nom prenom');
    if (!patient) return res.status(404).json({ error: 'Utilisateur introuvable' });
    if (patient.role !== 'patient') {
      return res.status(403).json({ error: 'Only patients can book appointments' });
    }

    const {
      doctor_user_id,
      start_date_time,
      duration_minutes,
      reason,
      notes,
      modality,
      video_url,
      facility_name,
      facility_address,
    } = req.body;
    if (!mongoose.isValidObjectId(doctor_user_id)) {
      return res.status(400).json({ error: 'Please select a valid doctor' });
    }
    const doctor = await User.findOne({
      _id: doctor_user_id,
      role: 'medecin',
      email_verifie: { $ne: false },
    }).select(DOCTOR_FIELDS);
    if (!doctor) return res.status(404).json({ error: 'Doctor not found' });

    const start = new Date(start_date_time);
    if (!start_date_time || Number.isNaN(start.getTime())) {
      return res.status(400).json({ error: 'A valid appointment date is required' });
    }
    if (!reason || !String(reason).trim()) {
      return res.status(400).json({ error: 'Appointment reason is required' });
    }
    const duration = Number(duration_minutes || 30);
    if (![15, 30, 45, 60].includes(duration)) {
      return res.status(400).json({ error: 'Invalid appointment duration' });
    }
    const visitMode =
      modality === 'teleconsultation' ? 'teleconsultation' : 'presentiel';

    const appointment = await Appointment.create({
      patient: patient._id,
      doctor: doctor._id,
      start_date_time: start,
      duration_minutes: duration,
      reason: String(reason).trim(),
      notes: notes == null ? '' : String(notes).trim(),
      modality: visitMode,
      video_url: video_url || null,
      facility_name: visitMode === 'presentiel' ? facility_name || '' : '',
      facility_address:
        visitMode === 'presentiel' ? facility_address || '' : '',
    });
    const result = await populated(Appointment.findById(appointment._id));
    res.status(201).json(toResponse(result));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.update = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.appointmentId)) {
      return res.status(400).json({ error: 'Invalid appointment ID' });
    }
    const appointment = await Appointment.findById(req.params.appointmentId);
    if (!appointment) return res.status(404).json({ error: 'Appointment not found' });

    const user = await User.findById(req.userId).select('role');
    const isDoctor =
      user?.role === 'medecin' && appointment.doctor.toString() === req.userId;
    const isPatient =
      user?.role === 'patient' && appointment.patient.toString() === req.userId;
    if (!isDoctor && !isPatient) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const fields = isDoctor
      ? [
          'start_date_time',
          'duration_minutes',
          'reason',
          'notes',
          'modality',
          'video_url',
          'facility_name',
          'facility_address',
          'status',
        ]
      : [
          'doctor_user_id',
          'start_date_time',
          'duration_minutes',
          'reason',
          'notes',
          'modality',
          'video_url',
          'facility_name',
          'facility_address',
        ];

    for (const field of fields) {
      if (!(field in req.body)) continue;
      if (field === 'status') {
        const doctorStatuses = [
          'SCHEDULED',
          'CONFIRMED',
          'RESCHEDULED',
          'CANCELLED_BY_PRACTITIONER',
          'COMPLETED',
          'MISSED',
        ];
        if (!doctorStatuses.includes(req.body.status)) {
          return res.status(400).json({ error: 'Invalid appointment status' });
        }
        appointment.status = req.body.status;
      } else if (field === 'doctor_user_id') {
        if (!mongoose.isValidObjectId(req.body[field])) {
          return res.status(400).json({ error: 'Please select a valid doctor' });
        }
        const doctor = await User.findOne({
          _id: req.body[field],
          role: 'medecin',
          email_verifie: { $ne: false },
        }).select('_id');
        if (!doctor) return res.status(404).json({ error: 'Doctor not found' });
        appointment.doctor = doctor._id;
      } else if (field === 'start_date_time') {
        const date = new Date(req.body[field]);
        if (Number.isNaN(date.getTime())) {
          return res.status(400).json({ error: 'Invalid appointment date' });
        }
        appointment[field] = date;
      } else if (field === 'duration_minutes') {
        const duration = Number(req.body[field]);
        if (![15, 30, 45, 60].includes(duration)) {
          return res.status(400).json({ error: 'Invalid appointment duration' });
        }
        appointment[field] = duration;
      } else {
        appointment[field] = req.body[field];
      }
    }

    await appointment.save();
    const result = await populated(Appointment.findById(appointment._id));
    res.json(toResponse(result));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

exports.remove = async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.appointmentId);
    if (!appointment) return res.status(404).json({ error: 'Appointment not found' });
    const user = await User.findById(req.userId).select('role');
    const isDoctor =
      user?.role === 'medecin' && appointment.doctor.toString() === req.userId;
    const isPatient =
      user?.role === 'patient' && appointment.patient.toString() === req.userId;
    if (!isDoctor && !isPatient) {
      return res.status(403).json({ error: 'Access denied' });
    }
    await appointment.deleteOne();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
