# Online component library (Supabase)

How it works

    you  ->  portal/index.html (admin login)  ->  Supabase table `components`
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
4. Open `portal/index.html` and check the two constants at the top
   (`SUPABASE_URL`, `SUPABASE_KEY`). They already contain this project's
   URL and publishable key.
5. Host `portal/index.html`: drag the `portal` folder into
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
