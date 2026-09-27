import 'package:flutter/material.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    // Navigate to dashboard
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Center Branding
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Printer Icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.print_rounded,
                          size: 54,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    const Text(
                      AppConstants.appSubtitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Version
                    const Text(
                      'v2.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Bottom Progress Bar & Loading Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Memuat aplikasi...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
