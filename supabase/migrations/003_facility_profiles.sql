-- ============================================================
-- Migration 003 — facility_profiles
-- Ragione sociale, tipo struttura, indirizzo, referente.
-- ============================================================

create table public.facility_profiles (
  id                uuid        references public.profiles(id) on delete cascade primary key,

  -- Dati aziendali
  company_name      text        not null,
  facility_type     text,       -- 'hospital', 'clinic', 'rsa', 'nursing_home', 'rehabilitation', 'other'
  vat_number        text,       -- partita IVA

  -- Sede
  address_street    text,
  address_city      text,
  address_province  text,
  address_postal    text,

  -- Referente interno
  contact_name      text,
  contact_phone     text,
  contact_email     text,

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table public.facility_profiles enable row level security;

-- Struttura: controllo completo del proprio profilo
create policy "Facility manages own profile"
  on public.facility_profiles for all
  using  (auth.uid() = id)
  with check (auth.uid() = id);

-- Infermieri: possono leggere i dati della struttura che ha pubblicato un turno
create policy "Nurse can view facility profiles"
  on public.facility_profiles for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'nurse'
    )
  );

-- ── Trigger updated_at ────────────────────────────────────────────────────────
create trigger on_facility_profiles_updated
  before update on public.facility_profiles
  for each row execute procedure public.handle_updated_at();
