import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UdderLogoWidget extends StatelessWidget {
  final double size;
  final bool showBadgeBorder;

  const UdderLogoWidget({
    super.key,
    this.size = 40,
    this.showBadgeBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/icons/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!showBadgeBorder) {
      return logo;
    }

    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: logo,
    );
  }
}
