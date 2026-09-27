import 'package:flutter/material.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';

class ThermalTicketContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ThermalTicketContainer({
    super.key,
    required this.child,
    this.maxWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: AppColors.thermalPaper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
