import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Gradient? gradient;
  final Color textColor;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.gradient,
    this.textColor = Colors.white,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;

    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: hasGradient ? Colors.transparent : (color ?? const Color(0xFF39A900)),
        foregroundColor: textColor,
        elevation: hasGradient ? 0 : 0,
        shadowColor: hasGradient ? Colors.transparent : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (hasGradient) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF238500).withOpacity(0.18),
                offset: const Offset(0, 10),
                blurRadius: 18,
              ),
            ],
          ),
          child: button,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: button,
    );
  }
}
