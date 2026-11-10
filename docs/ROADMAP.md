# Decode - Roadmap

Source of truth: the project brief + `docs/design_reference.png`.
Nothing below is marked done until it has been built and tried on a device.

## Written (version 0.7.0), awaiting device test

- Projects: create / rename / duplicate / search / delete / ZIP export.
- Open real folders from phone storage and save back in place
  (needs the "All files access" permission; file explorer drawer, tabs).
- Editor: native Flutter editor, colours for HTML / CSS / JS (also inside
  `<style>` and `<script>`), line numbers, find / replace, undo / redo,
  indent / outdent / comment, auto-close, smart Enter, VS Code style
  suggestion popup with snippets (`article` -> `<article></article>`).
- Live preview (WebView) and "Open in Chrome" through a loopback server.
- Component library: 11 basics + 6 design styles (18) + online components,
  inline preview and "Copy component" (one HTML file) in the detail screen.
- Online library: Supabase table + admin website (`portal/`). Components
  published there reach every app without an update.
- Local Admin Panel: bulk actions, backup / import.
- Splash screen, new launcher icon (adaptive).
- Explore tab: 300 colour palettes, gradient / shadow / glass / neumorphism
  generators, colour tools, lorem generator. Built-in demo components were
  removed; the library is filled from the portal and My Components.
- Editor: VS Code Light+/Dark+ colours, colour swatches with HSL picker,
  property-aware CSS suggestions (fonts, values), lorem snippets, status bar.
- Preview falls back to a bundled page when Android blocks the local server.
- Word wrap (default on) with aligned line numbers, current-line highlight,
  colour boxes shown before the colour, and popup placement.
- Explore: popular icon libraries and Google Fonts + pairings (web pages
  bundled in assets/web, need internet).
- Component categories are now real website component types (33), shared
  with Decode-Admin.html; old category names are mapped automatically.
- Import images into a project; Supabase Storage bucket for online images.

## Still to do

- JS console errors inside the app.
- Word wrap toggle.
- ZIP import.
- Signed release APK + download website.

## Notes

- Editor: a native editor was chosen over CodeMirror-in-WebView because
  Android keyboard composing inside a WebView is the biggest risk and could
  not be tested here. If it feels weak on a real phone, CodeMirror can still
  replace it behind `CodeEditorPane`.
- Preview server lives only while the preview screen is open; Chrome needs
  Decode to stay alive.
- Storage: "All files access" is fine for a sideloaded APK but Google Play
  would not accept it. A Play Store release would need the system file picker
  (Storage Access Framework) instead.
- Security: the app only READS from Supabase. Writes happen on the portal,
  behind Supabase Auth and Row Level Security (`supabase/schema.sql`).
