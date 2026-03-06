import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_app/staff_app/utils/get_storage.dart';
import 'package:student_app/student_app/services/student_profile_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    // Navigate after 2.5 seconds (slightly faster for better UX)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (AppStorage.isLoggedIn()) {
        final loginType = AppStorage.getLoginType();
        if (loginType == 'student') {
          // Initialize student profile data
          try {
            // ignore: unawaited_futures
            StudentProfileService.fetchAndSetProfileData();
          } catch (e) {
            debugPrint("Splash Profile Fetch Error: $e");
          }
          Get.offAllNamed('/studentDashboard');
        } else {
          Get.offAllNamed('/dashboard');
        }
      } else {
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFFE5DFFF), // Lighter, glowing center
              Color(0xFF9E92FF), // Transition color
              Color(0xFF7B6DFE), // Vibrant outer purple
            ],
            center: Alignment.center,
            radius: 1.1,
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutExpo, // Elegant, high-end feel
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value), // Scale from 80% to 100%
                  child: Container(
                    padding: const EdgeInsets.all(
                      40,
                    ), // Increased padding for a larger circle
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B6DFE).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 2,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/splash_screen.gif',
                      width: 180, // Slightly larger image
                      height: 180, // Slightly larger image
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school,
                        size: 100,
                        color: Color(0xFF7367F0),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
