import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'prescription_screen.dart';
import '../screens/splash_screen.dart'; // MediQueueTheme

class PatientJourneyScreen extends StatefulWidget {
  final int appointmentId;
  const PatientJourneyScreen({super.key, required this.appointmentId});

  @override
  State<PatientJourneyScreen> createState() => _PatientJourneyScreenState();
}

class _PatientJourneyScreenState extends State<PatientJourneyScreen> {
  Map? appointment;
  Map? prescription;
  Map? queue;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res  = await ApiService.getAppointment(auth.token!, widget.appointmentId);
      final pres = await ApiService.getPrescription(auth.token!, widget.appointmentId);
      if (!mounted) return;
      setState(() {
        appointment  = res['appointment'];
        queue        = res['queue'];
        prescription = pres;
        loading      = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  // ── Getters ──────────────────────────────────
  bool get _checkedIn => appointment?['status'] == 'checked_in' ||
      appointment?['checked_in_at'] != null;
  bool get _done => appointment?['status'] == 'done';
  bool get _hasPres => (prescription?['prescription']?['medications'] as List?)
          ?.isNotEmpty ?? false;

  int  get _position    => queue?['position'] ?? 0;
  int  get _before      => queue?['patients_before'] ?? 0;
  int  get _current     => queue?['current_number'] ?? 0;
  bool get _called      => queue?['called'] ?? false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: MediQueueTheme.background,
        body: Center(child: CircularProgressIndicator(color: MediQueueTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: MediQueueTheme.background,
      appBar: AppBar(
        backgroundColor: MediQueueTheme.surface,
        foregroundColor: MediQueueTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Mon parcours',
            style: GoogleFonts.dmSerifDisplay(
                fontSize: 20, color: MediQueueTheme.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: MediQueueTheme.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: MediQueueTheme.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildSteps(),
            const SizedBox(height: 24),
            if (_checkedIn && !_done) ...[_buildQueueCard(), const SizedBox(height: 20)],
            if (_hasPres) _buildPrescriptionCard(),
          ],
        ),
      ),
    );
  }

  // ── Étapes du parcours ───────────────────────
  Widget _buildSteps() {
    final steps = [
      {'label': 'Rendez-vous confirmé',  'icon': Icons.event_rounded,              'done': true},
      {'label': 'Check-in à l\'hôpital', 'icon': Icons.qr_code_scanner_rounded,    'done': _checkedIn},
      {'label': 'Consultation médicale', 'icon': Icons.medical_services_rounded,    'done': _done},
      {'label': 'Ordonnance disponible', 'icon': Icons.receipt_long_rounded,        'done': _hasPres},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final done = step['done'] as bool;
          final isLast = i == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne + icône
              Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: done ? MediQueueTheme.primary : MediQueueTheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done ? MediQueueTheme.primary : MediQueueTheme.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(step['icon'] as IconData,
                      size: 17,
                      color: done ? Colors.white : MediQueueTheme.textHint),
                ),
                if (!isLast)
                  Container(
                    width: 2, height: 28,
                    color: done ? MediQueueTheme.primaryLight.withOpacity(0.4)
                        : MediQueueTheme.divider,
                  ),
              ]),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(step['label'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                      color: done ? MediQueueTheme.textPrimary : MediQueueTheme.textHint,
                    )),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── File d'attente ───────────────────────────
  Widget _buildQueueCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.people_alt_rounded, color: MediQueueTheme.primary, size: 20),
            const SizedBox(width: 10),
            Text("File d'attente",
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: MediQueueTheme.textPrimary)),
          ]),
          const SizedBox(height: 16),

          if (_called)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MediQueueTheme.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MediQueueTheme.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.notifications_active_rounded,
                    color: MediQueueTheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text("C'est votre tour ! Veuillez entrer.",
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: MediQueueTheme.primary))),
              ]),
            )
          else
            Row(children: [
              // Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Votre position',
                        style: GoogleFonts.dmSans(
                            color: MediQueueTheme.textSecondary, fontSize: 12)),
                    Text('$_position',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 36, color: MediQueueTheme.primary)),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: MediQueueTheme.divider),
              // Avant
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avant vous',
                          style: GoogleFonts.dmSans(
                              color: MediQueueTheme.textSecondary, fontSize: 12)),
                      Text('$_before patient(s)',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              color: MediQueueTheme.textPrimary)),
                      if (_current > 0)
                        Text('En cours : N°$_current',
                            style: GoogleFonts.dmSans(
                                color: Colors.orange.shade700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  // ── Ordonnance ───────────────────────────────
  Widget _buildPrescriptionCard() {
    final pres = prescription?['prescription'];
    final qr   = pres?['qr_code'];
    final meds = pres?['medications'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.receipt_long_rounded, color: MediQueueTheme.primary, size: 20),
            const SizedBox(width: 10),
            Text('Ordonnance',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: MediQueueTheme.textPrimary)),
          ]),
          const SizedBox(height: 16),

          ...meds.map((m) {
            final pivot = m['pivot'] ?? {};
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MediQueueTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['name'] ?? '-',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: MediQueueTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    '${pivot['dosage'] ?? '-'} · ${pivot['frequency'] ?? '-'} · ${pivot['duration'] ?? '-'}',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: MediQueueTheme.textSecondary),
                  ),
                ],
              ),
            );
          }),

          if (qr != null) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MediQueueTheme.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(data: qr, size: 72),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code pharmacie',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: MediQueueTheme.textPrimary, fontSize: 13)),
                  const SizedBox(height: 4),
                  SelectableText(qr,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: MediQueueTheme.textSecondary)),
                ],
              )),
            ]),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MediQueueTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      PrescriptionScreen(appointmentId: widget.appointmentId))),
              child: Text('Voir les détails complets',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}