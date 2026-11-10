# Decode by Senpai Studio

Free, ad-free mobile coding IDE for Android. Built with Flutter.

> Your Phone. Your Code. Your Future.

## First-time setup

This repo contains the Dart source, assets and CI only. Generate the Android
runner once:

```bash
flutter create --org com.senpaistudio --project-name decode --platforms android .
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

`flutter create` will not overwrite the existing `lib/`, `pubspec.yaml` or
`test/` files. Commit the generated `android/` folder afterwards.

See `docs/ROADMAP.md` for the plan.

## Building without a local Flutter install

Push to GitHub. The "Build APK" workflow generates `android/`, runs
`tool/patch_android.py` (INTERNET permission, localhost-only cleartext, app
name, launcher icons) and uploads `app-debug.apk` as an artifact.

## Online components (Supabase)

See `docs/SUPABASE_SETUP.md`. Run `supabase/schema.sql` once, host
`portal/Decode-Admin.html`, and publish components from there.
