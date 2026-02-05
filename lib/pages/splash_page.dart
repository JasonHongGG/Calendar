import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/date_sticker_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entranceController;
  late AnimationController _hoverController;
  late AnimationController _backgroundController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _sloganFade;

  // Background Animations
  late Animation<Alignment> _topOrbAlign;
  late Animation<Alignment> _bottomOrbAlign;

  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // 1. Entrance Controller (One-shot)
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    // Logo: Elastic Scale + Slight Rotation
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Text: Staggered Slide & Fade
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _sloganFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Hover Controller (Looping)
    _hoverController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);

    // 3. Background Controller (Looping)
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);

    _topOrbAlign = AlignmentTween(begin: const Alignment(1.2, -1.2), end: const Alignment(0.6, -0.6)).animate(CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOutSine));

    _bottomOrbAlign = AlignmentTween(begin: const Alignment(-1.2, 1.2), end: const Alignment(-0.8, 0.8)).animate(CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOutSine));

    // Start Entrance
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _hoverController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      await initializeDateFormatting('zh_TW', null);
      await NotificationService().init();

      if (!mounted) return;
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.init();

      if (!mounted) return;
      final stickerProvider = Provider.of<DateStickerProvider>(context, listen: false);
      await stickerProvider.init();

      // Min duration to show off animation
      final elapsedTime = DateTime.now().difference(startTime);
      final minDuration = const Duration(milliseconds: 3000);
      if (elapsedTime < minDuration) {
        await Future.delayed(minDuration - elapsedTime);
      }

      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Init Error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- Dynamic Background ---
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Stack(
                children: [
                  Align(alignment: _topOrbAlign.value, child: _buildGradientOrb(300, AppColors.gradientStart.withValues(alpha: 0.15))),
                  Align(alignment: _bottomOrbAlign.value, child: _buildGradientOrb(250, AppColors.gradientEnd.withValues(alpha: 0.15))),
                ],
              );
            },
          ),

          // --- Main Content ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Hover & Parallax-like feel
                AnimatedBuilder(
                  animation: Listenable.merge([_entranceController, _hoverController]),
                  builder: (context, child) {
                    final hoverOffset = Offset(0, 10 * _hoverController.value);
                    return Transform.translate(
                      offset: hoverOffset,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: Transform.scale(scale: _logoScale.value, child: _buildLogoCard()),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Animated Text
                AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Opacity(
                            opacity: _textFade.value,
                            child: const Text(
                              'Smart Calendar',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.2, height: 1.2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: _sloganFade.value,
                            child: const Text(
                              'Plan your days efficiently',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textSecondary, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Error State Retry Button (Only if error)
          if (_hasError)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) => Opacity(opacity: value, child: child),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _hasError = false);
                      _initializeApp();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('重試'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gradientStart, foregroundColor: Colors.white, elevation: 4, shadowColor: AppColors.gradientStart.withValues(alpha: 0.4), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.gradientStart, AppColors.gradientEnd]).createShader(bounds),
          child: const Icon(
            Icons.calendar_month_rounded,
            size: 70,
            color: Colors.white, // Necessary for ShaderMask
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)],
      ),
    );
  }
}
