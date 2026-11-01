# Decode - Roadmap

Source of truth: the project brief + `docs/design_reference.png`.
Nothing below is marked done until it has been built and tried on a device.

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Editor spike (CodeMirror vs native) | Skipped: a native Flutter editor was written instead (see below) |
| 1 | Navigation, light/dark/system theme | Written, awaiting device test |
| 2 | Local projects: create/rename/duplicate/search/delete | Written, awaiting device test |
| 3 | Editor: tabs, highlighting, autocomplete, symbols, undo/redo, save + autosave | Written, awaiting device test |
| 4 | Live preview (WebView), Open in Chrome, quick preview | Written, awaiting device test |
| 5 | Component library: 11 basics, 6 design styles, My Components studio | Written, awaiting device test |
| 6 | Find/replace, ZIP export, editor settings, Admin Panel (manage, bulk actions, backup/import) | Written, awaiting device test |
| 7+ | Device testing, signed release APK, download website | TODO |

## Editor decision

A native Flutter editor (TextField + custom highlighter, auto-close, autocomplete
bar, symbol toolbar) was chosen over CodeMirror-in-WebView, because Android
keyboard composing inside a WebView is the biggest risk in the brief and could
not be tested here. If the native editor feels weak on a real phone, CodeMirror
can still be tried as a replacement behind `CodeEditorPane`.

## Preview and Chrome

A loopback-only (127.0.0.1) HTTP server serves the project folder, so relative
paths work in both the in-app WebView and Chrome. "Open in Chrome" uses an
Android intent for `com.android.chrome` and falls back to the default browser.
The server lives only while the preview screen is open, and Chrome needs Decode
to stay alive: if Android kills the app in the background, the Chrome tab
stops loading until the preview is opened again.

## Known gaps

- JavaScript console errors are not shown inside the app yet.
- HTML files do not colour embedded `<style>` / `<script>` blocks.
- No word-wrap toggle yet (the editor scrolls sideways).
- Components cannot be inserted into an existing project yet, only into a new one.
