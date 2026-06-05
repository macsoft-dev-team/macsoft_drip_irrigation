import 'package:flutter/material.dart';

class AppLoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? color;

  const AppLoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimary = color ?? Theme.of(context).primaryColor;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: themePrimary,
        disabledBackgroundColor: themePrimary.withValues(alpha: 0.6),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(label),
    );
  }
}
