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
  bool isBooking = false;

  // ── Recherche & affichage ─────────────────────
  bool isGridView = false;
  String searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> get _filteredServices {
    if (searchQuery.trim().isEmpty) return services;
    final q = searchQuery.toLowerCase();
    return services.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final data = await ApiService.getServices(auth.token!);
      if (!mounted) return;
      setState(() {
        services = List<Map<String, dynamic>>.from(
          data.map(
            (s) => {
              "id": s["id"],
              "name": s["name"] ?? "Service",
              "capacity": s["capacity"] ?? "-",
            },
          ),
        );
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  String _serviceNameById(int serviceId) {
    for (final s in services) {
      if (int.parse(s['id'].toString()) == serviceId) {
        return s['name']?.toString() ?? 'Service';
      }
    }
    return 'Service';
  }

  String _formatDisplayDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.parse(raw.toString());
      const months = [
        'jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  List<String> _availableTimeSlots(DateTime? selectedDate) {
    final slots = <String>[];
    for (int h = 8; h < 18; h++) {
      for (final m in [0, 30]) {
        slots.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
      }
    }
    if (selectedDate == null) return slots;

    final now = DateTime.now();
    if (selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day) {
      return slots.where((slot) {
        final parts = slot.split(':');
        final slotTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        return slotTime.isAfter(now);
      }).toList();
    }
    return slots;
  }

  Future<void> _showBookingSuccess({
    required String serviceName,
    required String date,
    required String time,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: MediQueueTheme.surface,
            borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
            border: Border.all(color: MediQueueTheme.divider),
            boxShadow: MediQueueTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 480),
                curve: Curves.elasticOut,
                builder: (_, scale, __) => Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: MediQueueTheme.primarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MediQueueTheme.primary.withOpacity(0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: MediQueueTheme.primary,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rendez-vous confirmé avec succès',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  color: MediQueueTheme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre demande a bien été enregistrée.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  color: MediQueueTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MediQueueTheme.background,
                  borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
                  border: Border.all(color: MediQueueTheme.divider),
                ),
                child: Column(
                  children: [
                    _successDetailRow(
                      Icons.medical_services_rounded,
                      'Service',
                      serviceName,
                    ),
                    const SizedBox(height: 12),
                    _successDetailRow(
                      Icons.calendar_today_rounded,
                      'Date',
                      _formatDisplayDate(date),
                    ),
                    const SizedBox(height: 12),
                    _successDetailRow(
                      Icons.schedule_rounded,
                      'Heure',
                      time.isNotEmpty ? time : '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(MediQueueTheme.radiusMd),
                    gradient: const LinearGradient(
                      colors: [
                        MediQueueTheme.primary,
                        MediQueueTheme.primaryLight,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MediQueueTheme.primary.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(MediQueueTheme.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Voir le rendez-vous',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: MediQueueTheme.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: MediQueueTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: MediQueueTheme.textHint,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: MediQueueTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Booking bottom sheet ─────────────────────
  Future<void> _openBooking(int serviceId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final serviceName = _serviceNameById(serviceId);
    DateTime? date;
    String? selectedTime;
    String? dateMode;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModal) {
          final timeSlots = _availableTimeSlots(date);

          return Container(
            margin: const EdgeInsets.only(top: 40),
            decoration: const BoxDecoration(
              color: MediQueueTheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(MediQueueTheme.radiusLg),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: MediQueueTheme.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MediQueueTheme.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MediQueueTheme.divider),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: MediQueueTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prendre rendez-vous',
                              style: GoogleFonts.dmSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: MediQueueTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              serviceName,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: MediQueueTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _sheetSectionLabel('Date'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dateBtn(
                          'Aujourd\'hui',
                          Icons.today_rounded,
                          isSelected: dateMode == 'today',
                          onTap: () => setModal(() {
                            dateMode = 'today';
                            date = DateTime.now();
                            selectedTime = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateBtn(
                          'Choisir',
                          Icons.edit_calendar_rounded,
                          isSelected: dateMode == 'custom',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (c, child) => Theme(
                                data: Theme.of(c).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: MediQueueTheme.primary,
                                    onPrimary: Colors.white,
                                    surface: MediQueueTheme.surface,
                                  ),
                                  dialogTheme: DialogThemeData(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        MediQueueTheme.radiusMd,
                                      ),
                                    ),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setModal(() {
                                dateMode = 'custom';
                                date = picked;
                                selectedTime = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: MediQueueTheme.primarySurface,
                        borderRadius:
                            BorderRadius.circular(MediQueueTheme.radiusMd),
                        border: Border.all(
                          color: MediQueueTheme.primary.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            color: MediQueueTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatDisplayDate(date),
                            style: GoogleFonts.dmSans(
                              color: MediQueueTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _sheetSectionLabel('Heure'),
                  const SizedBox(height: 12),
                  if (date == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MediQueueTheme.background,
                        borderRadius:
                            BorderRadius.circular(MediQueueTheme.radiusMd),
                        border: Border.all(color: MediQueueTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: MediQueueTheme.textHint,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sélectionnez d\'abord une date',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: MediQueueTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (timeSlots.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MediQueueTheme.background,
                        borderRadius:
                            BorderRadius.circular(MediQueueTheme.radiusMd),
                        border: Border.all(color: MediQueueTheme.divider),
                      ),
                      child: Text(
                        'Aucun créneau disponible pour aujourd\'hui.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: MediQueueTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: timeSlots.map((slot) {
                        final selected = selectedTime == slot;
                        return GestureDetector(
                          onTap: () => setModal(() => selectedTime = slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? MediQueueTheme.primary
                                  : MediQueueTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? MediQueueTheme.primary
                                    : MediQueueTheme.divider,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: MediQueueTheme.primary
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              slot,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : MediQueueTheme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(MediQueueTheme.radiusMd),
                        gradient: (date == null ||
                                selectedTime == null ||
                                isBooking)
                            ? null
                            : const LinearGradient(
                                colors: [
                                  MediQueueTheme.primary,
                                  MediQueueTheme.primaryLight,
                                ],
                              ),
                        boxShadow: (date == null ||
                                selectedTime == null ||
                                isBooking)
                            ? null
                            : [
                                BoxShadow(
                                  color: MediQueueTheme.primary
                                      .withOpacity(0.22),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (date == null ||
                                  selectedTime == null ||
                                  isBooking)
                              ? MediQueueTheme.textHint.withOpacity(0.35)
                              : Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          disabledBackgroundColor:
                              MediQueueTheme.textHint.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MediQueueTheme.radiusMd,
                            ),
                          ),
                        ),
                        onPressed: (date == null ||
                                selectedTime == null ||
                                isBooking)
                            ? null
                            : () async {
                                setModal(() => isBooking = true);

                                try {
                                  final res = await ApiService.createAppointment(
                                    auth.token!,
                                    serviceId,
                                    date!.toIso8601String().split("T")[0],
                                    selectedTime!,
                                  );

                                  Navigator.pop(ctx, res);
                                } catch (_) {
                                  Navigator.pop(ctx);
                                } finally {
                                  if (mounted) {
                                    setState(() => isBooking = false);
                                  }
                                }
                              },
                        child: isBooking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Confirmer le rendez-vous',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != null && mounted) {
      await _load();
      final apt = result['appointment'] ?? {};
      await _showBookingSuccess(
        serviceName: apt['service']?['name']?.toString() ?? serviceName,
        date: apt['date']?.toString() ?? '',
        time: apt['time']?.toString() ?? '',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AppointmentDetailScreen(appointment: result['appointment']),
        ),
      );
    }
  }

  Widget _sheetSectionLabel(String text) => Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: MediQueueTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MediQueueTheme.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );

  Widget _dateBtn(
    String label,
    IconData icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? MediQueueTheme.primarySurface : MediQueueTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? MediQueueTheme.primary.withOpacity(0.45)
                  : MediQueueTheme.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? MediQueueTheme.primary
                    : MediQueueTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: isSelected
                      ? MediQueueTheme.primary
                      : MediQueueTheme.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediQueueTheme.background,
      body: loading
          ? Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: MediQueueTheme.primary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(child: _buildSearchAndToggle()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                  sliver: _filteredServices.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmpty())
                      : isGridView
                          ? _buildGridSliver()
                          : _buildListSliver(),
                ),
              ],
            ),
    );
  }

  Widget _buildListSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _buildCard(_filteredServices[i]),
        childCount: _filteredServices.length,
      ),
    );
  }

  Widget _buildGridSliver() {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _buildGridCard(_filteredServices[i]),
        childCount: _filteredServices.length,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 210, // hauteur fixe en pixels, indépendante de la largeur
      ),
    );
  }

  // ── Recherche + toggle vue ───────────────────
  Widget _buildSearchAndToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 10),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        border: Border.all(color: MediQueueTheme.divider),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => searchQuery = v),
        style: GoogleFonts.dmSans(
          fontSize: 13.5,
          color: MediQueueTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un service...',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 13.5,
            color: MediQueueTheme.textHint,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: MediQueueTheme.textHint,
          ),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: MediQueueTheme.textHint,
                  ),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    searchQuery = '';
                  }),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        border: Border.all(color: MediQueueTheme.divider),
      ),
      child: Row(
        children: [
          _toggleBtn(
            Icons.view_list_rounded,
            !isGridView,
            () => setState(() => isGridView = false),
          ),
          _toggleBtn(
            Icons.grid_view_rounded,
            isGridView,
            () => setState(() => isGridView = true),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? MediQueueTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : MediQueueTheme.textHint,
        ),
      ),
    );
  }

  // ── Sliver App Bar ───────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 152,
      pinned: true,
      backgroundColor: MediQueueTheme.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Services médicaux',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 19,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${services.length} disponible${services.length > 1 ? 's' : ''}',
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MediQueueTheme.primary,
                    Color(0xFF0D5C3D),
                    MediQueueTheme.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Service Card (vue liste) ─────────────────
  Widget _buildCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        border: Border.all(color: MediQueueTheme.divider.withOpacity(0.85)),
        boxShadow: [
          BoxShadow(
            color: MediQueueTheme.primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: MediQueueTheme.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MediQueueTheme.divider),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: MediQueueTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'],
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: MediQueueTheme.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MediQueueTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MediQueueTheme.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 13,
                            color: MediQueueTheme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Capacité : ${s['capacity']}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: MediQueueTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildRdvButton(
                onTap: () => _openBooking(int.parse(s['id'].toString())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Service Card (vue grille) ────────────────
  Widget _buildGridCard(Map<String, dynamic> s) {
    return InkWell(
      onTap: () => _openBooking(int.parse(s['id'].toString())),
      borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: MediQueueTheme.surface,
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          border: Border.all(color: MediQueueTheme.divider.withOpacity(0.85)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MediQueueTheme.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: MediQueueTheme.primary.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: MediQueueTheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s['name'],
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: MediQueueTheme.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MediQueueTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MediQueueTheme.divider),
              ),
              child: Text(
                'Cap. ${s['capacity']}',
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  color: MediQueueTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: MediQueueTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRdvButton({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [MediQueueTheme.primary, MediQueueTheme.primaryLight],
            ),
            boxShadow: [
              BoxShadow(
                color: MediQueueTheme.primary.withOpacity(0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RDV',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────
  Widget _buildEmpty() {
    final isSearch = searchQuery.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: MediQueueTheme.divider),
            ),
            child: Icon(
              isSearch
                  ? Icons.search_off_rounded
                  : Icons.medical_services_outlined,
              size: 34,
              color: MediQueueTheme.textHint,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isSearch ? 'Aucun résultat' : 'Aucun service disponible',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MediQueueTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Essayez un autre terme de recherche.'
                : 'Revenez plus tard pour consulter les services.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: MediQueueTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}