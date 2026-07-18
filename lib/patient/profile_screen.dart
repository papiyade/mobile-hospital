import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../screens/splash_screen.dart';
import '../widgets/profile/edit_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;
  String? error;

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

  void _openEditProfile() {
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return EditProfileSheet(
          profile: profile!,
          onSaved: () {
            _loadProfile(); // refresh après update
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediQueueTheme.background,
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: MediQueueTheme.primary,
                strokeWidth: 2.5,
              ),
            )
          : error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: MediQueueTheme.textHint),
          const SizedBox(height: 12),
          Text(
            error!,
            style: GoogleFonts.dmSans(
              color: MediQueueTheme.textSecondary,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final user = profile?['user'] ?? {};
    final patient = profile?['patient'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: MediQueueTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _buildHeaderCard(user, patient),
          const SizedBox(height: 28),
          _sectionTitle("Informations personnelles"),
          const SizedBox(height: 10),
          _infoCard([
            _infoTile(Icons.phone_outlined, "Téléphone", patient['phone']),
            _infoTile(Icons.cake_outlined, "Naissance", patient['birth_date']),
            _infoTile(Icons.location_on_outlined, "Adresse", patient['address']),
          ]),
          const SizedBox(height: 24),
          _sectionTitle("Données médicales"),
          const SizedBox(height: 10),
          _infoCard([
            _infoTile(Icons.bloodtype_outlined, "Groupe sanguin",
                patient['blood_group']),
            _infoTile(Icons.warning_amber_rounded, "Allergies",
                patient['allergies']),
            _infoTile(Icons.medical_services_outlined, "Antécédents",
                patient['medical_history']),
          ]),
          const SizedBox(height: 24),
          _sectionTitle("Contact d'urgence"),
          const SizedBox(height: 10),
          _infoCard([
            _infoTile(Icons.person_pin_outlined, "Nom",
                patient['emergency_contact_name']),
            _infoTile(Icons.phone_in_talk_outlined, "Téléphone",
                patient['emergency_contact_phone']),
          ]),
          const SizedBox(height: 24),
          _sectionTitle("Actions"),
          const SizedBox(height: 10),
          _actionButton(Icons.refresh_rounded, "Rafraîchir", _loadProfile),
          const SizedBox(height: 10),
          _actionButton(
            Icons.logout_rounded,
            "Déconnexion",
            () => Provider.of<AuthProvider>(context, listen: false).logout(),
            danger: true,
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────

  Widget _buildHeaderCard(Map user, Map patient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
        border: Border.all(color: MediQueueTheme.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: MediQueueTheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                (user['name'] ?? 'U').toString()[0].toUpperCase(),
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 30,
                  color: MediQueueTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user['name'] ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: MediQueueTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            user['email'] ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: MediQueueTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _badge(patient['gender'] ?? 'non défini'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                "Modifier le profil",
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MediQueueTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MediQueueTheme.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MediQueueTheme.primary.withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MediQueueTheme.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ── Sections ──────────────────────────────

  Widget _sectionTitle(String title) {
    return Row(
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
          title,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MediQueueTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        border: Border.all(color: MediQueueTheme.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1)
              Divider(height: 1, color: MediQueueTheme.divider),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, dynamic value) {
    final display = (value == null || value.toString().isEmpty)
        ? '-'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: MediQueueTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: MediQueueTheme.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              display,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: MediQueueTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: MediQueueTheme.surface,
            borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
            border: Border.all(
              color: danger
                  ? Colors.red.withOpacity(0.25)
                  : MediQueueTheme.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: danger
                      ? Colors.red.withOpacity(0.08)
                      : MediQueueTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: danger ? Colors.red : MediQueueTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: danger ? Colors.red : MediQueueTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: MediQueueTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}