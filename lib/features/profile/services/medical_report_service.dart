import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../auth/models/user.dart';

/// Construit et partage (ou imprime) un compte-rendu médical au format PDF.
class MedicalReportService {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  static Future<void> exportPdf(User user) async {
    final doc = pw.Document(title: 'MediTrack – Medical Record');
    final black = PdfColor.fromInt(0xFF0A2540);
    final green = PdfColor.fromInt(0xFF0B6B5D);
    final grey = PdfColor.fromInt(0xFF5B6472);

    pw.Widget sectionTitle(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: green)),
        );

    pw.Widget row(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 150,
                child: pw.Text(label,
                    style: pw.TextStyle(fontSize: 10, color: grey)),
              ),
              pw.Expanded(
                child: pw.Text(value.isEmpty ? 'Not set' : value,
                    style: pw.TextStyle(
                        fontSize: 11,
                        color: black,
                        fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        );

    String dob() {
      final d = DateTime.tryParse(user.dateNaissance ?? '');
      if (d == null) return 'Not set';
      final age = user.age;
      return '${_months[d.month - 1]} ${d.day}, ${d.year}'
          '${age != null ? ' ($age yrs)' : ''}';
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          // En-tête
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFEDEFFD),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MediTrack',
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: green)),
                    pw.Text('Medical Record',
                        style: pw.TextStyle(fontSize: 12, color: grey)),
                  ],
                ),
                pw.Text(user.meditrackId,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: black)),
              ],
            ),
          ),

          sectionTitle('Patient'),
          row('Full Name', user.fullName),
          row('Role', user.roleLabel),
          row('Email', user.email),
          row('Phone', user.telephone ?? ''),
          row('Date of Birth', dob()),
          row('Sex', user.sexe ?? ''),
          row('Blood Group', user.groupeSanguin ?? ''),

          sectionTitle('Medical Condition'),
          row('Condition', user.conditionMedicale ?? ''),

          sectionTitle('Emergency Contact'),
          row('Name', user.contactUrgenceNom ?? ''),
          row('Relationship', user.contactUrgenceLien ?? ''),
          row('Phone', user.contactUrgenceTel ?? ''),

          sectionTitle('Care & Coverage'),
          row('Insurance Provider', user.assuranceNom ?? ''),
          row('Policy Number', user.assurancePolice ?? ''),

          sectionTitle('Primary Care Physicians'),
          if (user.medecins.isEmpty)
            row('Doctors', '')
          else
            ...user.medecins.map((m) => row(m.nom, m.specialite)),

          pw.SizedBox(height: 28),
          pw.Divider(color: PdfColor.fromInt(0xFFDDE4FA)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Document généré par MediTrack le '
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}.',
            style: pw.TextStyle(fontSize: 9, color: grey),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'MediTrack_${user.fullName.replaceAll(' ', '_')}.pdf',
    );
  }
}
