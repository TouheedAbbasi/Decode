import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in Chrome. Falls back to the default browser if Chrome is
/// missing. Returns false when nothing could open it.
Future<bool> openInChrome(String url) async {
  if (Platform.isAndroid) {
    try {
      await AndroidIntent(
        action: 'action_view',
        data: url,
        package: 'com.android.chrome',
      ).launch();
      return true;
    } catch (_) {
      // Chrome is not installed or refused; try the default browser.
    }
  }
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
