import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> copyText(
  BuildContext context,
  String text, {
  String message = 'Copied',
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
