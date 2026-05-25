import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'appointment_detail_screen.dart';
import 'splash_screen.dart'; // MediQueueTheme

class ServicesScreen extends StatefulWidget {
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<Map<String, dynamic>> services = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) { setState(() => loading = false); return; }
    try {
      final data = await ApiService.getServices(auth.token!);
      if (!mounted) return;
      setState(() {
        services = List<Map<String, dynamic>>.from(data.map((s) => {
          "id": s["id"],
          "name": s["name"] ?? "Service",
          "capacity": s["capacity"] ?? "-",
        }));
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  // ── Booking bottom sheet ─────────────────────
  Future<void> _openBooking(int serviceId) async {
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
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: MediQueueTheme.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MediQueueTheme.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      color: MediQueueTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Prendre rendez-vous',
                    style: GoogleFonts.dmSans(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: MediQueueTheme.textPrimary)),
              ]),

              const SizedBox(height: 24),

              // Boutons date
              Row(children: [
                Expanded(child: _dateBtn('Aujourd\'hui', Icons.today_rounded,
                    () => setModal(() => date = DateTime.now()))),
                const SizedBox(width: 12),
                Expanded(child: _dateBtn('Choisir', Icons.edit_calendar_rounded,
                    () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: MediQueueTheme.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => date = picked);
                })),
              ]),

              // Date sélectionnée
              if (date != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: MediQueueTheme.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MediQueueTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.event_available_rounded,
                        color: MediQueueTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${date!.day}/${date!.month}/${date!.year}',
                      style: GoogleFonts.dmSans(
                          color: MediQueueTheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // Bouton confirmer
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
                        auth.token!, serviceId,
                        date!.toIso8601String().split("T")[0],
                      );
                      Navigator.pop(ctx, res);
                    } catch (_) {
                      Navigator.pop(ctx);
                    }
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

  Widget _dateBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: MediQueueTheme.primary),
      label: Text(label,
          style: GoogleFonts.dmSans(
              color: MediQueueTheme.textPrimary, fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: MediQueueTheme.divider),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
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
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  sliver: services.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmpty())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildCard(services[i]),
                            childCount: services.length,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // ── Sliver App Bar ───────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: MediQueueTheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Services médicaux',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18, color: Colors.white)),
            Text('${services.length} disponibles',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A6E4A), Color(0xFF18A974)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // ── Service Card ─────────────────────────────
  Widget _buildCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_hospital_rounded,
                color: MediQueueTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'],
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: MediQueueTheme.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.people_outline_rounded,
                      size: 13, color: MediQueueTheme.textHint),
                  const SizedBox(width: 4),
                  Text('Capacité : ${s['capacity']}',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: MediQueueTheme.textSecondary)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _openBooking(int.parse(s['id'].toString())),
            style: ElevatedButton.styleFrom(
              backgroundColor: MediQueueTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('RDV',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.medical_services_outlined,
              size: 52, color: MediQueueTheme.textHint),
          const SizedBox(height: 16),
          Text('Aucun service disponible',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: MediQueueTheme.textSecondary)),
        ],
      ),
    );
  }
}