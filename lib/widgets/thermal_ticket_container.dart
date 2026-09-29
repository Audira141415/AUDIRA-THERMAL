import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';

class ThermalTicketContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final String? stampText;
  final Color? stampColor;

  const ThermalTicketContainer({
    super.key,
    required this.child,
    this.maxWidth = 360,
    this.stampText,
    this.stampColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: AppColors.thermalPaper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Tear Border Indicator
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                child: child,
              ),
              // Zigzag Serrated Bottom Edge
              ClipPath(
                clipper: ZigzagClipper(),
                child: Container(
                  height: 16,
                  color: AppColors.thermalPaper,
                ),
              ),
            ],
          ),

          // Angled Rubber Stamp Overlay (LUNAS / DP)
          if (stampText != null && stampText!.isNotEmpty)
            Positioned(
              right: 18,
              bottom: 60,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -math.pi / 12, // -15 degrees
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: (stampColor ?? AppColors.success).withOpacity(0.85),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stampText!.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: (stampColor ?? AppColors.success).withOpacity(0.85),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ZigzagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);

    const toothWidth = 10.0;
    const toothHeight = 10.0;
    final count = (size.width / toothWidth).ceil();

    for (int i = 0; i < count; i++) {
      final x1 = i * toothWidth + (toothWidth / 2);
      final y1 = toothHeight;
      final x2 = (i + 1) * toothWidth;
      final y2 = 0.0;

      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
