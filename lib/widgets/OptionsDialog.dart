import 'package:flutter/material.dart';

Future<void> showDeleteDialog({
  required Function() onPressed,
  required String actionText,
  required BuildContext context,
  required String titleText,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(titleText),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onPressed,
              child: Text(actionText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
