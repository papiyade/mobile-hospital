import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;

import 'login_screen.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────
//  CHARTE GRAPHIQUE MEDIQUEUE
//  À réutiliser sur toutes les pages
// ─────────────────────────────────────────────
class MediQueueTheme {
  static const Color primary        = Color(0xFF0A6E4A);
  static const Color primaryLight   = Color(0xFF18A974);
  static const Color primarySurface = Color(0xFFE8F5F0);
  static const Color background     = Color(0xFFF7FAF9);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF0D1F1A);
  static const Color textSecondary  = Color(0xFF557A6B);
  static const Color textHint       = Color(0xFF9DBFB4);
  static const Color divider        = Color(0xFFDCEDE6);
  static const Color error          = Color(0xFFD94F3D);

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0A6E4A), Color(0xFF0D5C3D), Color(0xFF092E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static TextStyle displayLarge({Color color = surface}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: 34, fontWeight: FontWeight.w400,
        color: color, letterSpacing: 0.5, height: 1.15,
      );

  static TextStyle headlineMedium({Color color = surface}) =>
      GoogleFonts.dmSans(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: color, letterSpacing: 0.2,
      );

  static TextStyle bodyMedium({Color color = textHint}) =>
      GoogleFonts.dmSans(
        fontSize: 13.5, fontWeight: FontWeight.w400,
        color: color, letterSpacing: 0.3, height: 1.5,
      );

  static TextStyle labelSmall({Color color = textHint}) =>
      GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w500,
        color: color, letterSpacing: 2.2,
      );

  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: primary.withOpacity(0.18), blurRadius: 32, offset: const Offset(0, 12)),
  ];
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(color: primary.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 8)),
  ];
}

// ─────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();

  late AnimationController _masterCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbitCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _loaderFade;
  late Animation<double> _pulse;
  late Animation<double> _orbit;

  int _dotIndex = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _setupAnimations();
    _masterCtrl.forward();
    _startDotAnimation();
    _checkAuth();
  }

  void _setupAnimations() {
    _masterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));
    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.1, 0.55, curve: Curves.elasticOut)));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.1, 0.4, curve: Curves.easeIn)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic)));
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.35, 0.65, curve: Curves.easeIn)));
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.55, 0.85, curve: Curves.easeIn)));
    _loaderFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.75, 1.0, curve: Curves.easeIn)));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _orbit = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear));
  }

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
      if (mounted) setState(() => _dotIndex = (_dotIndex + 1) % 4);
    });
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    final token = await _storage.read(key: 'token');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
pageBuilder: (_, __, ___) =>
    token != null ? HomeScreen() : LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: MediQueueTheme.primary,
      body: AnimatedBuilder(
        animation: Listenable.merge([_masterCtrl, _pulseCtrl, _orbitCtrl]),
        builder: (context, _) {
          return Stack(
            children: [
              Opacity(
                opacity: _bgFade.value,
                child: Container(decoration: const BoxDecoration(gradient: MediQueueTheme.splashGradient)),
              ),
              ..._buildDecorativeCircles(size),
              _buildOrbit(size),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                    const SizedBox(height: 8),
                    _buildSubtitle(),
                    const SizedBox(height: 48),
                    _buildLoader(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _pulse.value,
              child: Container(
                width: 116, height: 116,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
              ),
            ),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
              ),
            ),
            Container(
              width: 82, height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: MediQueueTheme.primaryLight.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 8)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: Column(
          children: [
            Text('SamaDoktor', style: MediQueueTheme.displayLarge()),
            const SizedBox(height: 6),
            Container(
              width: 36, height: 2.5,
              decoration: BoxDecoration(color: MediQueueTheme.primaryLight, borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _subtitleFade,
      child: Text(
        'Gestion intelligente des rendez-vous',
        style: MediQueueTheme.bodyMedium(color: Colors.white.withOpacity(0.55)).copyWith(fontSize: 13, letterSpacing: 0.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoader() {
    return FadeTransition(
      opacity: _loaderFade,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (i) {
              final active = i == _dotIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? MediQueueTheme.primaryLight : Colors.white.withOpacity(0.22),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            'Chargement en cours…',
            style: MediQueueTheme.bodyMedium(color: Colors.white.withOpacity(0.35)).copyWith(fontSize: 11, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Positioned(
      bottom: 32, left: 0, right: 0,
      child: FadeTransition(
        opacity: _subtitleFade,
        child: Column(
          children: [
            Container(width: 48, height: 1, color: Colors.white.withOpacity(0.12), margin: const EdgeInsets.only(bottom: 12)),
            Text(
              'VOTRE SANTÉ, NOTRE PRIORITÉ',
              style: MediQueueTheme.labelSmall(color: Colors.white.withOpacity(0.28)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeCircles(Size size) {
    return [
      Positioned(
        top: -size.width * 0.28, right: -size.width * 0.22,
        child: Opacity(opacity: 0.07,
          child: Container(width: size.width * 0.75, height: size.width * 0.75,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
      ),
      Positioned(
        top: -size.width * 0.06, right: size.width * 0.05,
        child: Opacity(opacity: 0.10,
          child: Container(width: size.width * 0.35, height: size.width * 0.35,
            decoration: BoxDecoration(shape: BoxShape.circle, color: MediQueueTheme.primaryLight.withOpacity(0.4)))),
      ),
      Positioned(
        bottom: -size.width * 0.35, left: -size.width * 0.25,
        child: Opacity(opacity: 0.06,
          child: Container(width: size.width * 0.85, height: size.width * 0.85,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)))),
      ),
      Positioned(
        top: size.height * 0.18, left: size.width * 0.12,
        child: Opacity(opacity: _pulse.value * 0.5,
          child: Container(width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: MediQueueTheme.primaryLight,
              boxShadow: [BoxShadow(color: MediQueueTheme.primaryLight.withOpacity(0.6), blurRadius: 10)]))),
      ),
      Positioned(
        top: size.height * 0.62, right: size.width * 0.10,
        child: Opacity(opacity: (2 - _pulse.value) * 0.45,
          child: Container(width: 4, height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8)]))),
      ),
    ];
  }

  Widget _buildOrbit(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const radius = 160.0;
    final dx = cx + radius * math.cos(_orbit.value);
    final dy = cy + radius * math.sin(_orbit.value);

    return Opacity(
      opacity: _logoFade.value * 0.18,
      child: Stack(
        children: [
          Center(
            child: Container(width: radius * 2, height: radius * 2,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8))),
          ),
          Positioned(
            left: dx - 4, top: dy - 4,
            child: Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: MediQueueTheme.primaryLight,
                boxShadow: [BoxShadow(color: MediQueueTheme.primaryLight.withOpacity(0.8), blurRadius: 12)])),
          ),
        ],
      ),
    );
  }
}