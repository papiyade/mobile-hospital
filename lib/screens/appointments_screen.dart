import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'appointment_detail_screen.dart';
import 'splash_screen.dart'; // MediQueueTheme

class AppointmentsScreen extends StatefulWidget {
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Map<String, dynamic>> appointments = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() { loading = false; error = "Session expirée"; });
      return;
    }
    try {
      final data = await ApiService.getAppointments(auth.token!);
      if (!mounted) return;
      setState(() {
        appointments = List<Map<String, dynamic>>.from(data);
        loading = false; error = null;
      });
    } catch (_) {
      if (mounted) setState(() { loading = false; error = "Erreur de chargement"; });
    }
  }

  // ── Helpers statut ───────────────────────────
  static const _statusOrder = ['checked_in', 'confirmed', 'pending', 'done', 'cancelled'];

  static const _statusLabel = {
    'pending': 'En attente', 'confirmed': 'Confirmé',
    'done': 'Terminé', 'checked_in': 'En consultation', 'cancelled': 'Annulé',
  };

  static const _statusColor = {
    'confirmed':  Color(0xFF16A34A), 'pending':    Color(0xFFF59E0B),
    'done':       Color(0xFF6B7280), 'checked_in': Color(0xFF0D9488),
    'cancelled':  Color(0xFFEF4444),
  };

  String _label(String? s) => _statusLabel[s] ?? 'Inconnu';
  Color  _color(String? s) => _statusColor[s] ?? Colors.grey;

  // ── Grouper + trier ──────────────────────────
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final sorted = [...appointments]..sort((a, b) {
      final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da); // plus récent en premier
    });

    final map = <String, List<Map<String, dynamic>>>{};
    for (final s in _statusOrder) {
      final list = sorted.where((a) => a['status'] == s).toList();
      if (list.isNotEmpty) map[s] = list;
    }
    return map;
  }

  // ── Quick booking sheet ──────────────────────
  Future<void> _openBooking() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    DateTime? date;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MediQueueTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: MediQueueTheme.divider,
                  borderRadius: BorderRadius.circular(10)),
              )),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MediQueueTheme.primarySurface,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: MediQueueTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Nouveau rendez-vous',
                    style: GoogleFonts.dmSans(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: MediQueueTheme.textPrimary)),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _dateBtn(ctx, setModal, 'Aujourd\'hui',
                    Icons.today_rounded, () => DateTime.now(), (d) => date = d)),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: MediQueueTheme.primary)),
                        child: child!),
                    );
                    if (picked != null) setModal(() => date = picked);
                  },
                  icon: const Icon(Icons.edit_calendar_rounded,
                      size: 16, color: MediQueueTheme.primary),
                  label: Text('Choisir', style: GoogleFonts.dmSans(
                      color: MediQueueTheme.textPrimary,
                      fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: MediQueueTheme.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )),
              ]),
              if (date != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: MediQueueTheme.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: MediQueueTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.event_available_rounded,
                        color: MediQueueTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text('${date!.day}/${date!.month}/${date!.year}',
                        style: GoogleFonts.dmSans(
                            color: MediQueueTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MediQueueTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: date == null ? null : () async {
                    try {
                      final res = await ApiService.createAppointment(
                        auth.token!, 1,
                        date!.toIso8601String().split("T")[0],
                      );
                      if (res['success'] == true) Navigator.pop(ctx, res['data']);
                      else Navigator.pop(ctx);
                    } catch (_) { Navigator.pop(ctx); }
                  },
                  child: Text('Confirmer le rendez-vous',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      await _load();
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => AppointmentDetailScreen(appointment: result)));
    }
  }

  Widget _dateBtn(BuildContext ctx, StateSetter setModal, String label,
      IconData icon, DateTime Function() getter, Function(DateTime) setter) {
    return OutlinedButton.icon(
      onPressed: () => setModal(() => setter(getter())),
      icon: Icon(icon, size: 16, color: MediQueueTheme.primary),
      label: Text(label, style: GoogleFonts.dmSans(
          color: MediQueueTheme.textPrimary, fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: const BorderSide(color: MediQueueTheme.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediQueueTheme.background,
      body: loading
          ? Center(child: CircularProgressIndicator(color: MediQueueTheme.primary))
          : error != null
              ? Center(child: Text(error!, style: GoogleFonts.dmSans(
                  color: MediQueueTheme.textSecondary)))
              : RefreshIndicator(
                  color: MediQueueTheme.primary,
                  onRefresh: _load,
                  child: _grouped.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MediQueueTheme.primary,
        onPressed: _openBooking,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildList() {
    final groups = _grouped;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: [
        // Compteur
        Text('${appointments.length} rendez-vous',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: MediQueueTheme.textSecondary)),
        const SizedBox(height: 20),
        // Sections par statut
        for (final status in groups.keys) ...[
          _buildSectionTitle(status),
          const SizedBox(height: 10),
          ...groups[status]!.map((a) => _buildCard(a)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String status) {
    final color = _color(status);
    return Row(children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(_label(status),
          style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 0.5)),
    ]);
  }

  Widget _buildCard(Map appt) {
    final status  = appt['status']?.toString();
    final service = appt['service'];
    final date    = appt['date'] ?? '-';
    final color   = _color(status);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AppointmentDetailScreen(appointment: appt))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MediQueueTheme.surface,
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          boxShadow: MediQueueTheme.cardShadow,
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: MediQueueTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service?['name'] ?? 'Service',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: MediQueueTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(date, style: GoogleFonts.dmSans(
                  fontSize: 12, color: MediQueueTheme.textSecondary)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_label(status),
                style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: MediQueueTheme.textHint, size: 20),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.35),
        Column(children: [
          Icon(Icons.calendar_today_outlined,
              size: 52, color: MediQueueTheme.textHint),
          const SizedBox(height: 16),
          Text('Aucun rendez-vous',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: MediQueueTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Appuyez sur + pour en créer un',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: MediQueueTheme.textHint)),
        ]),
      ],
    );
  }
}