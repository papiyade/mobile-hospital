import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart'; // MediQueueTheme

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;
  String? error;

  // ── SETTINGS (LOCAL STATE FUTUR BACKEND)
  bool smsNotifications = true;
  bool emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null) {
      setState(() {
        loading = false;
        error = "Session expirée";
      });
      return;
    }

    try {
      setState(() => loading = true);

      final data = await ApiService.getProfile(auth.token!);

      if (!mounted) return;

      setState(() {
        profile = data;
        error = null;
      });
    } catch (_) {
      setState(() {
        error = "Impossible de charger le profil";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediQueueTheme.background,

      body: loading
          ? Center(
              child: CircularProgressIndicator(color: MediQueueTheme.primary),
            )
          : error != null
          ? Center(child: Text(error!))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final user = profile?['user'] ?? {};
    final patient = profile?['patient'] ?? {};
    final stats = profile?['stats'] ?? {};

    return RefreshIndicator(
      color: MediQueueTheme.primary,
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          // ───────────────── HEADER ─────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: MediQueueTheme.primarySurface,
                  child: Text(
                    (user['name'] ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: MediQueueTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  user['name'] ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user['email'] ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: MediQueueTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 8),
                _badge(user['role'] ?? 'patient'),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ───────────────── STATS ─────────────────
          Row(
            children: [
              Expanded(child: _statCard("Total", stats['total_appointments'])),
              const SizedBox(width: 10),
              Expanded(child: _statCard("En attente", stats['pending'])),
            ],
          ),

          const SizedBox(height: 25),

          // ───────────────── INFO PERSONNELLE ─────────────────
          _sectionTitle("Informations personnelles"),
          const SizedBox(height: 10),

          _infoTile(Icons.phone, "Téléphone", patient['phone'] ?? '-'),
          _infoTile(Icons.cake, "Naissance", patient['birth_date'] ?? '-'),
          _infoTile(Icons.location_on, "Adresse", patient['address'] ?? '-'),

          const SizedBox(height: 25),

          // ───────────────── MODIFIER PROFIL ─────────────────
          _sectionTitle("Compte"),

          const SizedBox(height: 10),

          _actionButton(Icons.edit, "Modifier profil", () {
            // TODO: ouvrir edit profile screen
          }),

          const SizedBox(height: 10),

          _actionButton(Icons.lock_outline, "Sécurité du compte", () {}),

          const SizedBox(height: 30),

          // ───────────────── DONNÉES MÉDICALES (FUTUR) ─────────────────
          _sectionTitle("Données médicales"),

          const SizedBox(height: 10),

          _infoTile(Icons.bloodtype, "Groupe sanguin", "-"),
          _infoTile(Icons.warning_amber, "Allergies", "Non renseigné"),
          _infoTile(Icons.healing, "Maladies", "Aucune"),
          _infoTile(Icons.folder, "Dossier médical", "Accès bientôt"),

          const SizedBox(height: 30),

          // ───────────────── NOTIFICATIONS ─────────────────
          _sectionTitle("Notifications"),

          const SizedBox(height: 10),

          _switchTile(
            Icons.sms,
            "SMS",
            smsNotifications,
            (v) => setState(() => smsNotifications = v),
          ),

          _switchTile(
            Icons.email,
            "Email",
            emailNotifications,
            (v) => setState(() => emailNotifications = v),
          ),

          const SizedBox(height: 30),

          // ───────────────── SUPPORT ─────────────────
          _sectionTitle("Support"),

          const SizedBox(height: 10),

          _actionButton(Icons.help_outline, "FAQ", () {}),

          const SizedBox(height: 10),

          _actionButton(Icons.support_agent, "Contacter support", () {}),

          const SizedBox(height: 10),

          _actionButton(Icons.warning, "Urgence", () {}, danger: true),

          const SizedBox(height: 30),

          // ───────────────── ACTIONS ─────────────────
          _sectionTitle("Actions"),

          const SizedBox(height: 10),

          _actionButton(Icons.refresh, "Rafraîchir", _loadProfile),

          const SizedBox(height: 10),

          _actionButton(Icons.logout, "Déconnexion", () {
            Provider.of<AuthProvider>(context, listen: false).logout();
          }, danger: true),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ───────────────── WIDGETS ─────────────────

  Widget _badge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: MediQueueTheme.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MediQueueTheme.primary,
        ),
      ),
    );
  }

  Widget _statCard(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            "${value ?? 0}",
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: MediQueueTheme.primary,
            ),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: MediQueueTheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: MediQueueTheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF34C759),
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: danger ? Colors.red.withOpacity(0.08) : MediQueueTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: danger ? Colors.red : MediQueueTheme.primary),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}
