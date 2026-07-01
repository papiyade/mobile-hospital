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
  final _passwordFocus = FocusNode();
  bool    _loading   = false;
  bool    _showPass  = false;
  String? _errorMsg;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _passwordFocus.dispose();
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
              const SizedBox(height: 56),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildCard(),
              const SizedBox(height: 28),
              _buildRegisterLink(),
              const SizedBox(height: 40),
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
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: MediQueueTheme.primarySurface,
            borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
            border: Border.all(color: MediQueueTheme.divider),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: MediQueueTheme.primary,
            size: 26,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bon retour\nparmi nous',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            color: MediQueueTheme.textPrimary,
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connectez-vous pour gérer vos rendez-vous médicaux.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: MediQueueTheme.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ── Carte formulaire ─────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
        border: Border.all(color: MediQueueTheme.divider.withOpacity(0.7)),
        boxShadow: MediQueueTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Connexion'),
          const SizedBox(height: 20),
          _buildField(
            _identifier,
            'Email ou téléphone',
            Icons.person_outline_rounded,
            keyboard: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocus),
          ),
          const SizedBox(height: 18),
          _buildField(
            _password,
            'Mot de passe',
            Icons.lock_outline_rounded,
            isPassword: true,
            focusNode: _passwordFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: MediQueueTheme.error.withOpacity(0.07),
                borderRadius: BorderRadius.circular(MediQueueTheme.radiusSm),
                border: Border.all(color: MediQueueTheme.error.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: MediQueueTheme.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: MediQueueTheme.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MediQueueTheme.primary,
          letterSpacing: 1.4,
        ),
      );

  // ── Champ texte ──────────────────────────────
  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool isPassword = false,
    FocusNode? focusNode,
    TextInputAction textInputAction = TextInputAction.done,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: GoogleFonts.dmSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: MediQueueTheme.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          focusNode: focusNode,
          obscureText: isPassword && !_showPass,
          keyboardType: keyboard,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: MediQueueTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: MediQueueTheme.textHint,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(icon, color: MediQueueTheme.primary, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: MediQueueTheme.textHint,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  )
                : null,
            filled: true,
            fillColor: MediQueueTheme.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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
              borderSide: const BorderSide(
                color: MediQueueTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton connexion ─────────────────────────
  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
            gradient: _loading
                ? null
                : const LinearGradient(
                    colors: [
                      MediQueueTheme.primary,
                      MediQueueTheme.primaryLight,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: _loading
                ? null
                : [
                    BoxShadow(
                      color: MediQueueTheme.primary.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: _loading
                  ? MediQueueTheme.textHint.withOpacity(0.35)
                  : Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              disabledBackgroundColor:
                  MediQueueTheme.textHint.withOpacity(0.35),
              disabledForegroundColor: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Se connecter',
                        style: GoogleFonts.dmSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      );

  // ── Lien inscription ─────────────────────────
  Widget _buildRegisterLink() => Center(
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MediQueueTheme.surface,
              borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
              border: Border.all(color: MediQueueTheme.divider.withOpacity(0.8)),
            ),
            child: RichText(
              text: TextSpan(
                text: 'Pas encore de compte ? ',
                style: GoogleFonts.dmSans(
                  color: MediQueueTheme.textSecondary,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Créer un compte',
                    style: GoogleFonts.dmSans(
                      color: MediQueueTheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: MediQueueTheme.primary.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
