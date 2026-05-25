import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart'; // MediQueueTheme
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password   = TextEditingController();
  bool    _loading   = false;
  bool    _showPass  = false;
  String? _errorMsg;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _errorMsg = null);
    if (_identifier.text.isEmpty || _password.text.isEmpty) {
      setState(() => _errorMsg = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await auth.login(_identifier.text.trim(), _password.text);
      if (!mounted) return;
      setState(() => _loading = false);
      if (success) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        setState(() => _errorMsg = 'Identifiant ou mot de passe incorrect.');
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _errorMsg = 'Erreur réseau. Vérifiez votre connexion.'; });
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13.5)),
      backgroundColor: isError ? MediQueueTheme.error : MediQueueTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCard(),
              const SizedBox(height: 24),
              _buildRegisterLink(),
              const SizedBox(height: 32),
            ],
          ),
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
          'Bon retour\nparmi nous 👋',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 30,
            color: MediQueueTheme.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Connectez-vous pour gérer vos rendez-vous médicaux.',
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
          _sectionLabel('Connexion'),
          const SizedBox(height: 14),
          _buildField(_identifier, 'Email ou téléphone',
              Icons.person_outline_rounded,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildField(_password, 'Mot de passe',
              Icons.lock_outline_rounded, isPassword: true),
          const SizedBox(height: 28),
          _buildSubmitButton(),
          if (_errorMsg != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: MediQueueTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(MediQueueTheme.radiusSm),
                border: Border.all(color: MediQueueTheme.error.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline_rounded,
                    color: MediQueueTheme.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_errorMsg!,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: MediQueueTheme.error)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: MediQueueTheme.textHint,
          letterSpacing: 1.2,
        ),
      );

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

  // ── Bouton connexion ─────────────────────────
  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _login,
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
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Se connecter',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ),
      );

  // ── Lien inscription ─────────────────────────
  Widget _buildRegisterLink() => Center(
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: RichText(
            text: TextSpan(
              text: 'Pas encore de compte ? ',
              style: GoogleFonts.dmSans(
                  color: MediQueueTheme.textSecondary, fontSize: 13.5),
              children: [
                TextSpan(
                  text: 'Créer un compte',
                  style: GoogleFonts.dmSans(
                      color: MediQueueTheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      );
}