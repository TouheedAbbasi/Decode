/// Shown in Settings so you can tell which build you are running.
const appVersion = '0.7.0';

/// Set to true by the GitHub workflow (`--dart-define=DECODE_CI_PATCHED=true`)
/// after it has patched the Android project (permissions, icon, name).
/// If this is false, the build did not use the latest `ci.yml`.
const ciPatched = bool.fromEnvironment('DECODE_CI_PATCHED');
