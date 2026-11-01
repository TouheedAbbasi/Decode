# Decode - Roadmap

Source of truth: the project brief + `docs/design_reference.png`.

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Editor spike (CodeMirror 6 in WebView vs native Flutter editor) on real devices | TODO |
| 1 | Flutter project, navigation, light/dark/system theme | Written, awaiting device build |
| 2 | Local storage, Projects (create/rename/duplicate/search/delete), New Project | Written, awaiting device build |
| 3 | Editor: tabs, highlighting, autocomplete, symbol toolbar, autosave, find/replace | TODO |
| 4 | Live preview + **Open in Chrome** (see below) | TODO |
| 5 | Component library (offline) | TODO |
| 6 | Settings (editor options), ZIP export, polish | TODO |
| 7+ | Device testing, signed release APK, download website | TODO |

## Added requirement: open the preview in Chrome

From the Preview screen a button must open the current project in Chrome.

Plan:
1. Phase 4 starts a tiny HTTP server bound to `127.0.0.1` on a random port that
   serves the project folder (also used by the in-app WebView, so relative
   paths like `style.css` work the same in both).
2. "Open in Chrome" launches `http://127.0.0.1:<port>/index.html` with an
   Android intent targeting `com.android.chrome`, falling back to the default
   browser if Chrome is not installed.
3. Needs `INTERNET` permission and a network-security config allowing cleartext
   traffic to `127.0.0.1` only.

Known limitation: the server lives only while Decode is running. If Android
kills the app in the background, the Chrome tab stops loading until Decode is
reopened. `file://` URLs are not an option because Chrome cannot read an app's
private storage.
