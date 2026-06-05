-- ============================================================
-- Migration 005 — applications (candidature)
-- Struttura dati neutra: nessuna logica di accettazione automatica.
-- ============================================================

create table public.applications (
  id          uuid        default gen_random_uuid() primary key,
  shift_id    uuid        not null references public.shifts(id) on delete cascade,
  nurse_id    uuid        not null references public.nurse_profiles(id) on delete cascade,

  -- Stato candidatura
  -- pending → accepted | rejected   (decisione struttura — TODO business logic)
  --         → withdrawn              (ritiro infermiere)
  status      text        not null default 'pending'
                check (status in ('pending', 'accepted', 'rejected', 'withdrawn')),

  note        text,       -- nota facoltativa dell'infermiere

  -- TODO(business): logica di accettazione/rifiuto da definire:
  --   - Selezione manuale da parte della struttura
  --   - Accettazione automatica tramite algoritmo di matching
  --   - Trigger di pagamento/prenotazione al momento dell'accettazione
  --   Aggiungere policy RLS UPDATE per la struttura quando la logica è definita.

  applied_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  -- Un infermiere può candidarsi a un turno una sola volta
  unique (shift_id, nurse_id)
);

create index idx_applications_nurse_id on public.applications (nurse_id);
create index idx_applications_shift_id on public.applications (shift_id);
create index idx_applications_status   on public.applications (status);

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table public.applications enable row level security;

-- Infermieri: vedono e gestiscono le proprie candidature
create policy "Nurse views own applications"
  on public.applications for select
  using (nurse_id = auth.uid());

create policy "Nurse applies to published shift"
  on public.applications for insert
  with check (
    nurse_id = auth.uid()
    and exists (
      select 1 from public.shifts
      where id = shift_id and status = 'published'
    )
  );

create policy "Nurse can withdraw own application"
  on public.applications for update
  using  (nurse_id = auth.uid())
  with check (status = 'withdrawn');

-- Strutture: vedono le candidature ai propri turni (sola lettura per ora)
create policy "Facility views applications for own shifts"
  on public.applications for select
  using (
    exists (
      select 1 from public.shifts
      where id = shift_id and facility_id = auth.uid()
    )
  );

-- ── Trigger updated_at ────────────────────────────────────────────────────────
create trigger on_applications_updated
  before update on public.applications
  for each row execute procedure public.handle_updated_at();
