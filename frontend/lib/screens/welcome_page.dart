import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'role_selection_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // AIREA Logo - Lungs illustration
              _buildLogo(),

              const SizedBox(height: 16),

              // AIREA Text
              const Text(
                'AIREA',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5F7E),
                  letterSpacing: 12,
                ),
              ),

              const SizedBox(height: 48),

              // Description
              const Text(
                'Smart Respiratory\nMonitor for Early Lung\nCancer Detection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(flex: 1),

              // Get Started Button
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Get started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(140, 140),
          painter: LungsPainter(),
        ),
      ),
    );
  }
}

// Custom painter for lungs logo
class LungsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C5F7E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = const Color(0xFF5EBAA8).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw lungs shape (simplified)
    final leftLungPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.2, size.height * 0.2,
        size.width * 0.15, size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.15, size.height * 0.8,
        size.width * 0.35, size.height * 0.9,
      )
      ..lineTo(size.width * 0.45, size.height * 0.5)
      ..close();

    final rightLungPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.8, size.height * 0.2,
        size.width * 0.85, size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.85, size.height * 0.8,
        size.width * 0.65, size.height * 0.9,
      )
      ..lineTo(size.width * 0.55, size.height * 0.5)
      ..close();

    // Draw trachea
    final tracheaPath = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.5, size.height * 0.3);

    canvas.drawPath(leftLungPath, fillPaint);
    canvas.drawPath(rightLungPath, fillPaint);
    canvas.drawPath(leftLungPath, paint);
    canvas.drawPath(rightLungPath, paint);
    canvas.drawPath(tracheaPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

