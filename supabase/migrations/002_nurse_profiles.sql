-- ============================================================
-- Migration 002 — nurse_profiles
-- Dati anagrafici, abilitazione professionale, documenti.
-- Nessuna logica di verifica: campi predisposti, verifica = TODO.
-- ============================================================

create table public.nurse_profiles (
  id                  uuid        references public.profiles(id) on delete cascade primary key,

  -- Anagrafica
  first_name          text,
  last_name           text,
  date_of_birth       date,
  tax_code            text,                          -- codice fiscale
  phone               text,
  city                text,
  province            text,
  postal_code         text,

  -- Abilitazione professionale (OPI — Ordine Prof. Infermieristiche)
  -- TODO(onboarding): verifica documenti e abilitazione dipende dal flusso
  --   di onboarding ancora da definire (manuale, automatica, terze parti)
  qualification_type  text,                         -- es. 'infermiere', 'infermiere_pediatrico', 'ostetrica'
  license_number      text,                         -- numero iscrizione albo
  license_province    text,                         -- provincia OPI
  specializations     text[]      default '{}',     -- es. ['terapia_intensiva', 'pediatria']

  -- Riferimenti a Supabase Storage (path, non URL pubblica)
  -- TODO(onboarding): processo di verifica documenti da definire
  id_document_path    text,
  cv_path             text,
  nursing_cert_path   text,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table public.nurse_profiles enable row level security;

-- Infermiere: controllo completo del proprio profilo
create policy "Nurse manages own profile"
  on public.nurse_profiles for all
  using  (auth.uid() = id)
  with check (auth.uid() = id);

-- Strutture: possono leggere i profili degli infermieri candidati ai propri turni
create policy "Facility can view nurse profiles"
  on public.nurse_profiles for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'facility'
    )
  );

-- ── Trigger updated_at ────────────────────────────────────────────────────────
create trigger on_nurse_profiles_updated
  before update on public.nurse_profiles
  for each row execute procedure public.handle_updated_at();
