import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Asks for access to the phone's shared storage so the editor can open and
/// save real folders (Documents, Downloads, ...). Android 11 and newer show
/// the "All files access" screen; older versions show a normal dialog.
Future<bool> ensureStorageAccess() async {
  if (!Platform.isAndroid) return true;
  try {
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;

    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;
    status = await Permission.storage.request();
    return status.isGranted;
  } catch (_) {
    return false;
  }
}

/// Opens Android's settings page for this app.
Future<void> openStorageSettings() => openAppSettings();
