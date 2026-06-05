-- ============================================================
-- Migration 004 — shifts (turni)
-- Struttura dati neutra: nessuna logica di matching o compenso.
-- ============================================================

create table public.shifts (
  id              uuid        default gen_random_uuid() primary key,
  facility_id     uuid        not null references public.facility_profiles(id) on delete cascade,

  -- Identificazione
  title           text,
  description     text,
  required_role   text        not null,   -- ruolo infermieristico richiesto

  -- Orario
  start_at        timestamptz not null,
  end_at          timestamptz not null,

  -- Stato ciclo di vita
  -- draft → published → filled | cancelled
  --                   → completed (dopo esecuzione)
  status          text        not null default 'draft'
                    check (status in ('draft', 'published', 'filled', 'cancelled', 'completed')),

  -- TODO(business): campi compenso/tariffa — dipendono dal modello contrattuale
  --   e dalla struttura fiscale/giuridica del rapporto infermiere-piattaforma.
  --   Esempi: hourly_rate, total_fee, currency, payment_method, invoice_required

  -- TODO(matching): campi per algoritmo di matching — es. required_specializations,
  --   min_experience_years, preferred_nurse_id, matching_score

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint shifts_end_after_start check (end_at > start_at)
);

-- Indici per le query più frequenti
create index idx_shifts_facility_id on public.shifts (facility_id);
create index idx_shifts_status       on public.shifts (status);
create index idx_shifts_start_at     on public.shifts (start_at desc);

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table public.shifts enable row level security;

-- Struttura: gestione completa dei propri turni
create policy "Facility manages own shifts"
  on public.shifts for all
  using  (facility_id = auth.uid())
  with check (facility_id = auth.uid());

-- Infermieri: possono leggere solo i turni pubblicati
create policy "Nurse can view published shifts"
  on public.shifts for select
  using (
    status = 'published'
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'nurse'
    )
  );

-- ── Trigger updated_at ────────────────────────────────────────────────────────
create trigger on_shifts_updated
  before update on public.shifts
  for each row execute procedure public.handle_updated_at();
