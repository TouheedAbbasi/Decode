-- Decode: online component library.
-- Run this once in Supabase: SQL Editor > New query > paste > Run.
--
-- BEFORE running:
--   1. Authentication > Users > Add user > create YOUR admin account
--      (email + password, tick "Auto Confirm User").
--   2. Copy that user's UID and paste it in place of
--      PASTE-ADMIN-USER-UUID-HERE below (two places).
--   3. Authentication > Sign In / Providers (or Settings): turn OFF
--      "Allow new users to sign up". Nobody else can ever become admin.

create table if not exists public.components (
  id          text primary key,
  name        text not null,
  description text not null default '',
  category    text not null default 'UI',
  html        text not null,
  css         text not null default '',
  js          text not null default '',
  published   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists components_set_updated_at on public.components;
create trigger components_set_updated_at
  before update on public.components
  for each row execute function public.set_updated_at();

alter table public.components enable row level security;

-- Everybody (the app) may READ published components.
drop policy if exists "public can read published" on public.components;
create policy "public can read published"
  on public.components
  for select
  to anon, authenticated
  using (published = true);

-- Only the admin may read drafts, add, change or delete.
drop policy if exists "admin full access" on public.components;
create policy "admin full access"
  on public.components
  for all
  to authenticated
  using (auth.uid() = 'PASTE-ADMIN-USER-UUID-HERE'::uuid)
  with check (auth.uid() = 'PASTE-ADMIN-USER-UUID-HERE'::uuid);

grant select on public.components to anon, authenticated;
grant insert, update, delete on public.components to authenticated;
