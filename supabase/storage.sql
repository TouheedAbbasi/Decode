-- Decode: image storage for components and templates.
-- Run ONCE in Supabase > SQL Editor, after schema.sql.
-- Paste your admin user UID in place of PASTE-ADMIN-USER-UUID-HERE (one place).

create or replace function public.is_decode_admin()
returns boolean
language sql
stable
as $$
  select auth.uid() = 'PASTE-ADMIN-USER-UUID-HERE'::uuid
$$;

-- A PUBLIC bucket: anyone can open an image by its link, which is what a
-- component needs to show its pictures.
insert into storage.buckets (id, name, public)
values ('assets', 'assets', true)
on conflict (id) do update set public = true;

drop policy if exists "assets public read" on storage.objects;
create policy "assets public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'assets');

-- Only the admin may upload, replace or delete.
drop policy if exists "assets admin insert" on storage.objects;
create policy "assets admin insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'assets' and public.is_decode_admin());

drop policy if exists "assets admin update" on storage.objects;
create policy "assets admin update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'assets' and public.is_decode_admin())
  with check (bucket_id = 'assets' and public.is_decode_admin());

drop policy if exists "assets admin delete" on storage.objects;
create policy "assets admin delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'assets' and public.is_decode_admin());
