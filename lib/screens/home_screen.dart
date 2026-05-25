import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'services_screen.dart';
import 'appointments_screen.dart';
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

      if (!mounted) return;

      setState(() {
        appointments = data['appointments'] ?? [];
        servicesCount = data['services_count'] ?? 0;
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
      backgroundColor: MediQueueTheme.surface,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'SamaDoktor',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: MediQueueTheme.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_rounded,
                color: MediQueueTheme.textPrimary,
                size: 24,
              ),
              onPressed: token == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(token: token!),
                        ),
                      );
                    },
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          color: Colors.redAccent,
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Bottom Nav ───────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: const Color(0xFF0C513E).withOpacity(0.92),
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
          items: [
            _navItem(Icons.home_outlined, Icons.home_rounded, 'Accueil'),
            _navItem(
              Icons.medical_services_outlined,
              Icons.medical_services_rounded,
              'Services',
            ),
            _navItem(
              Icons.calendar_today_outlined,
              Icons.calendar_today_rounded,
              'Mes RDV',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
    IconData outline,
    IconData filled,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Opacity(opacity: 0.45, child: Icon(outline)),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: MediQueueTheme.primarySurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(filled, color: MediQueueTheme.primary),
      ),
      label: label,
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: MediQueueTheme.primary),
      );
    }

    // ── RefreshIndicator = pull-to-refresh ──────
    return RefreshIndicator(
      color: MediQueueTheme.primary,
      backgroundColor: MediQueueTheme.surface,
      displacement: 20,
      onRefresh: onRefresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(), // obligatoire pour le pull même si peu de contenu
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 20),
          _buildNextRdv(),
          const SizedBox(height: 20),
          _buildSectionTitle('Accès rapide'),
          const SizedBox(height: 12),
          _buildMenuGrid(context),
          const SizedBox(height: 20),
          _buildSectionTitle('Raccourcis'),
          const SizedBox(height: 12),
          _buildQuickPills(),
        ],
      ),
    );
  }

  // ── Hero Card ────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A6E4A), Color(0xFF18A974)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
        boxShadow: MediQueueTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour 👋',
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Votre suivi médical',
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStat('${appointments.length}', 'Total RDV'),
              _buildStatDivider(),
              _buildStat('$_pending', 'En attente'),
              _buildStatDivider(),
              _buildStat('$_confirmed', 'Confirmés'),
              _buildStatDivider(),
              _buildStat('$_done', 'Terminés'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _buildStatDivider() =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2));

  // ── Prochain RDV ─────────────────────────────
  Widget _buildNextRdv() {
    if (_nextAppointment == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: MediQueueTheme.surface,
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          border: Border.all(color: MediQueueTheme.divider),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: MediQueueTheme.textHint,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Aucun rendez-vous à venir',
              style: GoogleFonts.dmSans(
                color: MediQueueTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final date = DateTime.parse(_nextAppointment!['date']);
    final doctor = _nextAppointment!['doctor']?['user']?['name'] ?? 'Médecin';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: MediQueueTheme.primary,
              size: 20,
            ),
          ),
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
                const SizedBox(height: 3),
                Text(
                  'Dr. $doctor · ${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.dmSans(
                    color: MediQueueTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _timeLeft(date),
              style: GoogleFonts.dmSans(
                color: Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLeft(DateTime d) {
    final diff = d.difference(DateTime.now());
    if (diff.inDays > 1) return '${diff.inDays}j';
    if (diff.inDays == 1) return 'Demain';
    if (diff.inHours > 1) return '${diff.inHours}h';
    return 'Bientôt';
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: MediQueueTheme.textPrimary,
      letterSpacing: 0.3,
    ),
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
            color: const Color(0xFFE8F5F0),
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
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AppointmentsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick Pills ──────────────────────────────
  Widget _buildQuickPills() {
    final pills = [
      {'label': 'Urgence', 'icon': Icons.warning_amber_rounded},
      {'label': 'Pharmacie', 'icon': Icons.local_pharmacy_outlined},
      {'label': 'Résultats', 'icon': Icons.description_outlined},
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
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: MediQueueTheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: MediQueueTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      p['icon'] as IconData,
                      size: 16,
                      color: MediQueueTheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      p['label'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: MediQueueTheme.textPrimary,
                        fontWeight: FontWeight.w500,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: MediQueueTheme.surface,
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          boxShadow: MediQueueTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: MediQueueTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: MediQueueTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
