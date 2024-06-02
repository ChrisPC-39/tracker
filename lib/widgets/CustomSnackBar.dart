import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    Function? onActionPressed,
    Color? backgroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  onActionPressed?.call();
                },
              )
            : null,
        duration: duration ?? const Duration(seconds: 5),
        backgroundColor: backgroundColor ?? Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 6.0,
      ),
    );
  }
}
