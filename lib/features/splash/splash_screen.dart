import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:funeralface_mobile/app/session/auth_session.dart';
import 'package:funeralface_mobile/core/env.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen branded splash shown on app launch.
///
/// Displays the EverRoute logo on a forest-green background for [_displayDuration],
/// then navigates to /auth (when Supabase is configured and user is not signed in)
/// or /dashboard (when already authenticated or Supabase is not configured).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = Duration(milliseconds: 2200);
  static const _fadeDuration = Duration(milliseconds: 600);

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _fadeDuration);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(_displayDuration, _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    if (!AppEnv.hasSupabaseAuthConfig ||
        AuthSession.instance.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D6A4F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/Splash logo.svg',
                    width: 220,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _BrandText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'EVERROUTE',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'FUNERAL',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }
}
