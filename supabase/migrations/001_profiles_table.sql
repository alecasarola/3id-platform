-- ============================================================
-- Migration 001 — profiles table (Step 2: auth role storage)
-- Extended with more fields in Step 3.
-- Apply via: Supabase dashboard → SQL Editor, or Supabase CLI.
-- ============================================================

create table public.profiles (
  id          uuid        references auth.users(id) on delete cascade primary key,
  role        text        not null check (role in ('nurse', 'facility')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ── Row Level Security ────────────────────────────────────────────────────────
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using  (auth.uid() = id)
  with check (auth.uid() = id);

-- ── Auto-create profile on registration ─────────────────────────────────────
-- The Flutter client passes `data: {'role': 'nurse'|'facility'}` in signUp().
-- This trigger reads raw_user_meta_data and creates the profile row
-- automatically — no client-side INSERT needed, works with email confirmation.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'role', 'nurse')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── Auto-update updated_at ────────────────────────────────────────────────────
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger on_profiles_updated
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();
