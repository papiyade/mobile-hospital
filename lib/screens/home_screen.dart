import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'services_screen.dart';
import 'appointments_screen.dart';
import '../patient/profile_screen.dart';
import 'notifications_screen.dart';
import 'splash_screen.dart'; // MediQueueTheme

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  List appointments = [];
  int servicesCount = 0;
  int unreadNotificationsCount = 0;
  bool loading = true;
  Timer? _timer;
  String? token;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh toutes les 30 secondes
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadData(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => loading = true);

    try {
      final t = await storage.read(key: 'token');
      if (t == null) throw Exception('Token introuvable');

      token = t; // ✅ AJOUT IMPORTANT

      final data = await ApiService.getHomeData(t);

      int unread = unreadNotificationsCount;
      try {
        final notifs = await ApiService.getNotifications(t);
        unread = notifs.where((n) => n['read'] == false).length;
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        appointments = data['appointments'] ?? [];
        servicesCount = data['services_count'] ?? 0;
        unreadNotificationsCount = unread;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleLogout() async {
    final token = await storage.read(key: 'token');
    try {
      if (token != null) await ApiService.logout(token);
    } catch (_) {}
    await storage.delete(key: 'token');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeContent(
        appointments: appointments,
        servicesCount: servicesCount,
        loading: loading,
        onRefresh: _loadData, // ← pull-to-refresh branché ici
      ),
      ServicesScreen(),
      AppointmentsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: MediQueueTheme.background,
      appBar: _buildAppBar(),
      body: pages[_index.clamp(0, pages.length - 1)],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ───────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: MediQueueTheme.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: MediQueueTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MediQueueTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: MediQueueTheme.primary.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SamaDoktor',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 19,
                  color: MediQueueTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                'Espace patient',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: MediQueueTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildNotificationButton(),
        _buildLogoutButton(),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: MediQueueTheme.divider.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: MediQueueTheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: token == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(token: token!),
                      ),
                    ).then((_) => _loadData(silent: true));
                  },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MediQueueTheme.divider),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: MediQueueTheme.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
        if (unreadNotificationsCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: EdgeInsets.symmetric(
                horizontal: unreadNotificationsCount > 9 ? 5 : 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: MediQueueTheme.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MediQueueTheme.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: MediQueueTheme.error.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                unreadNotificationsCount > 99
                    ? '99+'
                    : '$unreadNotificationsCount',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: MediQueueTheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleLogout,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MediQueueTheme.error.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: MediQueueTheme.error,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
      (Icons.medical_services_outlined, Icons.medical_services_rounded, 'Services'),
      (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Mes RDV'),
      (Icons.person_outline, Icons.person, 'Profil'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: MediQueueTheme.divider.withOpacity(0.85)),
        boxShadow: [
          BoxShadow(
            color: MediQueueTheme.primary.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = _index == i;
          final (outline, filled, label) = items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _index = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? MediQueueTheme.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? filled : outline,
                      size: 22,
                      color: selected
                          ? MediQueueTheme.primary
                          : MediQueueTheme.textHint,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? MediQueueTheme.primary
                            : MediQueueTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CONTENU PRINCIPAL
// ─────────────────────────────────────────────
class _HomeContent extends StatelessWidget {
  final List appointments;
  final int servicesCount;
  final bool loading;
  final Future<void> Function() onRefresh; // ← reçoit le callback

  const _HomeContent({
    required this.appointments,
    required this.servicesCount,
    required this.loading,
    required this.onRefresh,
  });

  Map? get _nextAppointment {
    final upcoming = appointments.where((a) => a['status'] != 'done').toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort(
      (a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])),
    );
    return upcoming.first;
  }

  int get _pending => appointments.where((a) => a['status'] == 'pending').length;
  int get _confirmed => appointments.where((a) => a['status'] == 'confirmed').length;
  int get _done => appointments.where((a) => a['status'] == 'done').length;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: MediQueueTheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // ── RefreshIndicator = pull-to-refresh ──────
    return RefreshIndicator(
      color: MediQueueTheme.primary,
      backgroundColor: MediQueueTheme.surface,
      displacement: 24,
      strokeWidth: 2.5,
      onRefresh: onRefresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(), // obligatoire pour le pull même si peu de contenu
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 22),
          _buildNextRdv(),
          const SizedBox(height: 28),
          _buildSectionTitle('Accès rapide'),
          const SizedBox(height: 14),
          _buildMenuGrid(context),
          const SizedBox(height: 28),
          _buildSectionTitle('Raccourcis'),
          const SizedBox(height: 14),
          _buildQuickPills(),
        ],
      ),
    );
  }

  // ── Hero Card ────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            MediQueueTheme.primary,
            Color(0xFF0D5C3D),
            MediQueueTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
        boxShadow: MediQueueTheme.elevatedShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        'Tableau de bord',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$_greeting 👋',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Votre suivi médical',
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Consultez vos rendez-vous et services en un coup d\'œil.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    // _buildStat('${appointments.length}', 'Total', Icons.event_note_rounded),
                    const SizedBox(width: 8),
                    _buildStat('$_pending', 'Attente', Icons.schedule_rounded),
                    const SizedBox(width: 8),
                    _buildStat('$_confirmed', 'Confirmés', Icons.check_circle_outline_rounded),
                    const SizedBox(width: 8),
                    // _buildStat('$_done', 'Terminés', Icons.done_all_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 14),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.dmSerifDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  // ── Prochain RDV ─────────────────────────────
  Widget _buildNextRdv() {
    if (_nextAppointment == null) {
      return _surfaceCard(
        child: Row(
          children: [
            _iconBadge(Icons.event_busy_rounded, MediQueueTheme.textHint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prochain rendez-vous',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: MediQueueTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aucun rendez-vous à venir pour le moment',
                    style: GoogleFonts.dmSans(
                      color: MediQueueTheme.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final date = DateTime.parse(_nextAppointment!['date']);
    final doctor = _nextAppointment!['doctor']?['user']?['name'] ?? 'Médecin';

    return _surfaceCard(
      child: Row(
        children: [
          _iconBadge(Icons.calendar_today_rounded, MediQueueTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prochain rendez-vous',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: MediQueueTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Dr. $doctor',
                  style: GoogleFonts.dmSans(
                    color: MediQueueTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: GoogleFonts.dmSans(
                    color: MediQueueTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MediQueueTheme.divider),
            ),
            child: Text(
              _timeLeft(date),
              style: GoogleFonts.dmSans(
                color: MediQueueTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        border: Border.all(color: MediQueueTheme.divider.withOpacity(0.85)),
        boxShadow: [
          BoxShadow(
            color: MediQueueTheme.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: MediQueueTheme.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MediQueueTheme.divider),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  String _timeLeft(DateTime d) {
    final diff = d.difference(DateTime.now());
    if (diff.inDays > 1) return '${diff.inDays}j';
    if (diff.inDays == 1) return 'Demain';
    if (diff.inHours > 1) return '${diff.inHours}h';
    return 'Bientôt';
  }

  Widget _buildSectionTitle(String title) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: MediQueueTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MediQueueTheme.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );

  // ── Menu Grid ────────────────────────────────
  Widget _buildMenuGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MenuCard(
            title: 'Services',
            subtitle: '$servicesCount disponibles',
            icon: Icons.medical_services_rounded,
            color: MediQueueTheme.primarySurface,
            iconColor: MediQueueTheme.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ServicesScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MenuCard(
            title: 'Mes RDV',
            subtitle: '${appointments.length} rendez-vous',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFFEAF4F8),
            iconColor: const Color(0xFF2B7A8C),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AppointmentsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MenuCard(
            title: 'Profil',
            subtitle: 'Informations',
            icon: Icons.person_rounded,
            color: const Color(0xFFFDF3E6),
            iconColor: const Color(0xFFB36B00),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
          ),
        ),
      ],
    );
  }

  // ── Quick Pills ──────────────────────────────
  Widget _buildQuickPills() {
    final pills = [
      {'label': 'Urgence', 'icon': Icons.emergency_rounded},
      {'label': 'Pharmacie', 'icon': Icons.local_pharmacy_rounded},
      {'label': 'Résultats', 'icon': Icons.assignment_outlined},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pills
            .map(
              (p) => Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: MediQueueTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MediQueueTheme.divider),
                  boxShadow: [
                    BoxShadow(
                      color: MediQueueTheme.primary.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: MediQueueTheme.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        p['icon'] as IconData,
                        size: 15,
                        color: MediQueueTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      p['label'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: MediQueueTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MENU CARD
// ─────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color, iconColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MediQueueTheme.surface,
      borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withOpacity(0.12),
                      ),
                    ),
                    child: Icon(icon, color: iconColor, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: MediQueueTheme.textHint,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: MediQueueTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: MediQueueTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
