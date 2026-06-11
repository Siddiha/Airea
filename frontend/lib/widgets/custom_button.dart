import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isOutlined;
  final double? width;
  final Color? backgroundColor;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isOutlined = false,
    this.width,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: onPressed,
          style: AppTheme.outlineButton(),
          child: Text(text, style: AppTheme.buttonTextStyle),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: isPrimary
            ? AppTheme.primaryButton().copyWith(
                backgroundColor: backgroundColor != null
                    ? WidgetStatePropertyAll(backgroundColor)
                    : null,
              )
            : AppTheme.secondaryButton().copyWith(
                backgroundColor: backgroundColor != null
                    ? WidgetStatePropertyAll(backgroundColor)
                    : null,
              ),
        child: Text(
          text,
          style: AppTheme.buttonTextStyle,
        ),
      ),
    );
  }
}
