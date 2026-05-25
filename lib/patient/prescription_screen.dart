import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../screens/splash_screen.dart'; // MediQueueTheme
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PrescriptionScreen extends StatefulWidget {
  final int appointmentId;
  const PrescriptionScreen({super.key, required this.appointmentId});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  Map? prescription;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _openPdf(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

  Future<void> _load() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = await ApiService.getPrescription(auth.token!, widget.appointmentId);
      if (mounted) setState(() { prescription = data; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  // ── Couleurs locales (charte verte claire) ───
  static const _accent    = MediQueueTheme.primary;
  static const _accentDim = MediQueueTheme.primarySurface;
  static final  _accentBdr = MediQueueTheme.primary.withOpacity(0.25);
  static const _surface   = MediQueueTheme.surface;
  static const _bg        = MediQueueTheme.background;
  static const _border    = MediQueueTheme.divider;
  static const _txtPri    = MediQueueTheme.textPrimary;
  static const _txtSec    = MediQueueTheme.textSecondary;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    final meds = prescription?['prescription']?['medications'] as List? ?? [];
    final qr   = prescription?['prescription']?['qr_code']?.toString();
    final pdfUrl = prescription?['pdf_url'];

    Widget _buildPdfCard(String url) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _border),
  ),
  child: Row(
    children: [
      const Icon(Icons.picture_as_pdf, color: _accent),
      const SizedBox(width: 10),
      const Expanded(
        child: Text("Ordonnance PDF disponible"),
      ),
      TextButton(
        onPressed: () => _openPdf(url),
        child: const Text("Voir"),
      )
    ],
  ),
);

    if (prescription == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(),
        body: Center(
          child: Text('Aucune ordonnance disponible',
              style: GoogleFonts.dmSans(color: _txtSec, fontSize: 14)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          if (qr != null) ...[_buildQrCard(qr), const SizedBox(height: 20)],
          _sectionHeader(Icons.medication_rounded, '${meds.length} médicament(s)'),
          const SizedBox(height: 12),
          ...meds.map((m) => _MedCard(m: m)),
          if (pdfUrl != null) ...[
  const SizedBox(height: 20),
  _buildPdfCard(pdfUrl),
],
        ],
      ),
    );
  }

  AppBar _appBar() => AppBar(
        backgroundColor: _surface,
        foregroundColor: _txtPri,
        elevation: 0,
        centerTitle: true,
        title: Text('Ordonnance',
            style: GoogleFonts.dmSerifDisplay(
                fontSize: 20, color: _txtPri)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      );

  Widget _sectionHeader(IconData icon, String label) => Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _accentDim,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accentBdr),
          ),
          child: Icon(icon, color: _accent, size: 17),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.dmSans(
                color: _txtPri, fontSize: 14, fontWeight: FontWeight.w700)),
      ]);

  Widget _buildQrCard(String qr) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: MediQueueTheme.cardShadow,
        ),
        child: Row(children: [
          // QR image
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentDim,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accentBdr),
            ),
            child: QrImageView(
              data: qr, size: 100,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: _accent),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: _accent),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.qr_code_2_rounded, color: _accent, size: 16),
                const SizedBox(width: 6),
                Text('Code pharmacie',
                    style: GoogleFonts.dmSans(
                        color: _txtPri, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text('Présentez ce QR à votre pharmacien pour récupérer vos médicaments.',
                  style: GoogleFonts.dmSans(
                      color: _txtSec, fontSize: 11, height: 1.5)),
              const SizedBox(height: 10),
              SelectableText(qr,
                  style: GoogleFonts.dmMono(
                      color: _accent, fontSize: 10)),
            ]),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────
//  CARTE MÉDICAMENT
// ─────────────────────────────────────────────
class _MedCard extends StatelessWidget {
  final dynamic m;
  const _MedCard({required this.m});

  static const _accent    = MediQueueTheme.primary;
  static const _accentDim = MediQueueTheme.primarySurface;
  static const _surface   = MediQueueTheme.surface;
  static const _bg        = MediQueueTheme.background;
  static const _border    = MediQueueTheme.divider;
  static const _txtPri    = MediQueueTheme.textPrimary;
  static const _txtSec    = MediQueueTheme.textSecondary;

  @override
  Widget build(BuildContext context) {
    final pivot = m['pivot'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _accentDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MediQueueTheme.primary.withOpacity(0.2)),
          ),
          child: const Icon(Icons.medication_liquid_rounded,
              color: _accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m['name'] ?? '-',
                style: GoogleFonts.dmSans(
                    color: _txtPri, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _pill('💊 ${pivot['dosage'] ?? '-'}'),
              _pill('🕐 ${pivot['frequency'] ?? '-'}'),
              _pill('📅 ${pivot['duration'] ?? '-'}'),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Text(text,
            style: GoogleFonts.dmSans(color: _txtSec, fontSize: 10)),
      );
}