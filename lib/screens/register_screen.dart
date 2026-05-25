import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'splash_screen.dart'; // MediQueueTheme

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _phone    = TextEditingController();
  final _password = TextEditingController();
  final _address  = TextEditingController();

  bool _loading  = false;
  bool _showPass = false;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose();
    _password.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_email.text.isEmpty && _phone.text.isEmpty) {
      _showSnack("Email ou téléphone requis", isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
await ApiService.register(
  name: _name.text.trim(),
  email: _email.text.isEmpty ? null : _email.text.trim(),
  phone: _phone.text.isEmpty ? null : _phone.text.trim(),
  password: _password.text,
  address: _address.text.isEmpty ? null : _address.text.trim(),
);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } catch (_) {
      _showSnack("Erreur lors de l'inscription", isError: true);
    }

    setState(() => _loading = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13.5)),
        backgroundColor: isError ? MediQueueTheme.error : MediQueueTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediQueueTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildBackButton(),
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton retour ────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: MediQueueTheme.surface,
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusSm),
          boxShadow: MediQueueTheme.cardShadow,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: MediQueueTheme.textPrimary,
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créer un\ncompte 🏥',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 30,
            color: MediQueueTheme.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Rejoignez SamaDoktor et prenez rendez-vous facilement.',
          style: GoogleFonts.dmSans(
            fontSize: 13.5,
            color: MediQueueTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Carte formulaire ─────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Informations personnelles'),
          const SizedBox(height: 14),
          _buildField(_name,  'Nom complet',          Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _buildField(_email, 'Email (optionnel)',     Icons.email_outlined,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildField(_phone, 'Téléphone (optionnel)', Icons.phone_outlined,
              keyboard: TextInputType.phone),
          const SizedBox(height: 14),
          _buildField(_address, 'Adresse (optionnel)', Icons.location_on_outlined),

          const SizedBox(height: 22),
          _divider(),
          const SizedBox(height: 22),

          _sectionLabel('Sécurité'),
          const SizedBox(height: 14),
          _buildField(_password, 'Mot de passe', Icons.lock_outline_rounded,
              isPassword: true),

          const SizedBox(height: 28),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ── Label de section ─────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: MediQueueTheme.textHint,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Divider léger ────────────────────────────
  Widget _divider() {
    return Divider(color: MediQueueTheme.divider, thickness: 1, height: 1);
  }

  // ── Champ texte ──────────────────────────────
  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword && !_showPass,
      keyboardType: keyboard,
      style: GoogleFonts.dmSans(fontSize: 14, color: MediQueueTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: MediQueueTheme.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: MediQueueTheme.textHint, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: MediQueueTheme.textHint, size: 20,
                ),
                onPressed: () => setState(() => _showPass = !_showPass),
              )
            : null,
        filled: true,
        fillColor: MediQueueTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          borderSide: BorderSide(color: MediQueueTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          borderSide: BorderSide(color: MediQueueTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          borderSide: BorderSide(color: MediQueueTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── Bouton soumettre ─────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: MediQueueTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'Créer mon compte',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}