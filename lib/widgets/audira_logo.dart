import 'package:flutter/material.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';

class AudiraLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final Color? textColor;

  const AudiraLogoWidget({
    super.key,
    this.size = 48,
    this.showText = true,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppColors.text;
    final txtColor = textColor ?? AppColors.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Car / Multimedia Digital Silhouette Icon
        Icon(
          Icons.directions_car_filled_rounded,
          size: size,
          color: logoColor,
        ),
        if (showText) ...[
          const SizedBox(height: 4),
          Text(
            'AUDIRA',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: size * 0.36,
              fontWeight: FontWeight.w900,
              color: txtColor,
              letterSpacing: 2.0,
            ),
          ),
          Text(
            'MULTIMEDIA DIGITAL',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: size * 0.18,
              fontWeight: FontWeight.w700,
              color: txtColor.withOpacity(0.85),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
