# Online component library (Supabase)

How it works

    you  ->  portal/Decode-Admin.html (admin login)  ->  Supabase table `components`
                                                        |
    every phone  ->  Decode app downloads the list  <---+
                     (cached, so it also works offline)

Nobody has to update the app: publishing in the portal makes the component
appear in every app the next time it is opened (or pulled down to refresh).

## One-time setup

1. Create the admin user: Supabase > Authentication > Users > Add user.
   Use your email + a strong password and tick "Auto Confirm User".
   Copy the user's UID.
2. Open `supabase/schema.sql`, replace `PASTE-ADMIN-USER-UUID-HERE`
   (two places) with that UID, then run the whole file in
   Supabase > SQL Editor.
3. Turn OFF "Allow new users to sign up" in the Auth settings.
4. Open `portal/Decode-Admin.html` and check the two constants at the top
   (`SUPABASE_URL`, `SUPABASE_KEY`). They already contain this project's
   URL and publishable key.
5. Host `portal/Decode-Admin.html`: drag the `portal` folder into
   https://app.netlify.com/drop, or use Cloudflare Pages / Vercel, or just
   open the file from your phone/PC. (GitHub Pages needs a public repo.)

## Safety rules

- The URL and the publishable key are public by design. What protects your
  data is Row Level Security (the SQL above) + the admin login.
- NEVER put the `secret` / `service_role` key in the app or in the portal.
- Only components with `published = true` are visible to the app.
- Components run inside a sandboxed preview, but only publish code you wrote
  or trust: it is shown to every user.

## Free plan note

Free Supabase projects are paused after about a week without any activity.
Normal app use counts as activity; if it ever pauses, press "Restore" in the
dashboard.

## Images for components (Storage)

Run `supabase/storage.sql` once (paste your admin UID in the one place it
asks for). It creates a PUBLIC bucket called `assets`.

- Upload: open the portal, press **Images**, choose pictures.
- Use: press **Copy link** or **Copy <img>** and paste it in your component
  code. The link works for every user, so the picture also shows inside the
  app (needs internet, like all online images).
- Only the admin can upload or delete; everyone can view.

Images for your own projects inside the app: in the editor open the Files
panel and press the "add photo" button. The picture is copied into the
project (default folder `img/`) and the path is copied for you.

## Decode-Admin.html (AI + many components at once)

`portal/Decode-Admin.html` is the whole admin site in one file.

- Host it on Netlify: drag the `portal` folder into https://app.netlify.com/drop.
  The `_redirects` file makes the page open at the site address itself.
- AI Studio writes several components at the same time. Add one or more API
  keys under **AI Settings**. Keys are stored only in that browser
  (localStorage, or sessionStorage when "Remember keys" is off). They are
  never written into the file and are sent only to the provider you picked.
- Providers: Google Gemini, Groq, OpenRouter (free models), Mistral,
  Cerebras and any OpenAI-compatible endpoint. Model names change often, so
  use the **Load** button next to the model box.
- Use **Test all & sort by speed** to put the fastest provider first.
