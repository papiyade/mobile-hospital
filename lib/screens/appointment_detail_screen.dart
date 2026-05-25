import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../patient/patient_journey_screen.dart';
import 'splash_screen.dart'; // MediQueueTheme

class AppointmentDetailScreen extends StatelessWidget {
  final Map appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  // ── Helpers ──────────────────────────────────
  String _safe(dynamic v) => v?.toString() ?? '-';

  String _statusLabel(String? s) {
    const map = {
      'pending': 'En attente', 'confirmed': 'Confirmé',
      'done': 'Terminé', 'checked_in': 'Présent', 'cancelled': 'Annulé',
    };
    return map[s] ?? 'Inconnu';
  }

  Color _statusColor(String? s) {
    const map = {
      'confirmed': Color(0xFF16A34A), 'pending': Color(0xFFF59E0B),
      'done': Color(0xFF3B82F6),     'checked_in': Color(0xFF0D9488),
      'cancelled': Color(0xFFEF4444),
    };
    return map[s] ?? Colors.grey;
  }

  Color _statusBg(String? s) => _statusColor(s).withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    final serviceName  = _safe(appointment['service']?['name']);
    final date         = _safe(appointment['date']);
    final statusRaw    = appointment['status']?.toString();
    final qrCode       = appointment['qr_code']?.toString();
    final position     = appointment['queue_number'] ?? 1;
    final consultTime  = appointment['service']?['consultation_time'] ?? 15;
    final estimatedMin = consultTime * position;
    final doctorData   = appointment['doctor'];
    final doctor       = (doctorData is Map && doctorData['user'] is Map)
        ? doctorData['user']['name'] ?? 'Non assigné'
        : 'Non assigné';

    return Scaffold(
      backgroundColor: MediQueueTheme.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildHeader(context, serviceName, date, statusRaw),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildInfoCard(position, estimatedMin, doctor),
                      if (qrCode != null) ...[
                        const SizedBox(height: 20),
                        _buildQrCard(qrCode),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(context, appointment['id']),
        ],
      ),
    );
  }

  // ── Sliver Header ────────────────────────────
  Widget _buildHeader(BuildContext ctx, String name, String date, String? status) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: MediQueueTheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A6E4A), Color(0xFF18A974)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(name,
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 22)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(date,
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(status),
                      style: GoogleFonts.dmSans(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info Card ────────────────────────────────
  Widget _buildInfoCard(int position, int estMin, String doctor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Column(children: [
        _infoTile(Icons.format_list_numbered_rounded,
            'Position dans la file', '#$position'),
        _divider(),
        _infoTile(Icons.access_time_rounded,
            'Temps estimé', '$estMin min'),
        _divider(),
        _infoTile(Icons.person_outline_rounded,
            'Médecin', doctor),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: MediQueueTheme.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: MediQueueTheme.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: GoogleFonts.dmSans(
                color: MediQueueTheme.textSecondary, fontSize: 13.5))),
        Text(value,
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: MediQueueTheme.textPrimary,
                fontSize: 14)),
      ]),
    );
  }

  Widget _divider() => Divider(
      color: MediQueueTheme.divider, height: 1, thickness: 1);

  // ── QR Card ──────────────────────────────────
  Widget _buildQrCard(String qrCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.qr_code_2_rounded,
              color: MediQueueTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text('Votre QR Code',
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: MediQueueTheme.textPrimary)),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MediQueueTheme.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(data: qrCode, size: 160),
        ),
        const SizedBox(height: 14),
        Text('Présentez ce code à l\'accueil',
            style: GoogleFonts.dmSans(
                color: MediQueueTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }

  // ── Action Button ────────────────────────────
  Widget _buildActionButton(BuildContext context, dynamic appointmentId) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: MediQueueTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.timeline_rounded, size: 20),
            label: Text('Voir mon parcours médical',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) =>
                  PatientJourneyScreen(appointmentId: appointmentId)),
            ),
          ),
        ),
      ),
    );
  }
}