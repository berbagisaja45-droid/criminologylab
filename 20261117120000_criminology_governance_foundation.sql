-- Criminology Lab — Phase 0 / Governance Foundation
-- Additive migration only. No existing tables or data are dropped or rewritten.
-- IMPORTANT: This project already has a hosted Supabase database. Capture and
-- review its current schema with `supabase db pull --remote` before applying
-- any migration. Re-order this migration after the generated remote baseline
-- migration if the baseline has an earlier/later timestamp conflict.

begin;

-- -----------------------------------------------------------------------------
-- 1. Shared helper functions
-- -----------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. User profile and application roles
-- New users always start as viewer. An administrator must promote curators.
-- -----------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  role text not null default 'viewer'
    check (role in ('viewer', 'curator', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_curator_or_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role in ('curator', 'admin')
  );
$$;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), '')
    ),
    'viewer'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- -----------------------------------------------------------------------------
-- 3. Source registry (MS-Keg support)
-- -----------------------------------------------------------------------------

create table if not exists public.data_sources (
  id uuid primary key default gen_random_uuid(),
  source_code text not null unique
    check (source_code ~ '^[A-Z0-9][A-Z0-9_.-]{1,59}$'),
  source_type text not null default 'official_statistics'
    check (source_type in (
      'official_statistics', 'administrative', 'survey', 'research',
      'geospatial', 'international', 'other'
    )),
  title text not null,
  publisher text,
  description text,
  source_url text,
  license_name text,
  access_date date,
  reference_period text,
  visibility text not null default 'internal'
    check (visibility in ('public', 'internal')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 4. Dataset catalogue (MS-Keg support)
-- This table stores catalogue metadata, not raw person-level crime records.
-- -----------------------------------------------------------------------------

create table if not exists public.datasets (
  id uuid primary key default gen_random_uuid(),
  dataset_code text not null unique
    check (dataset_code ~ '^[A-Z0-9][A-Z0-9_.-]{1,79}$'),
  title text not null,
  description text,
  subject_area text not null default 'general_criminology',
  source_id uuid references public.data_sources (id) on delete set null,
  source_title text,
  source_url text,
  publisher text,
  observation_unit text,
  geographic_level text not null default 'other'
    check (geographic_level in (
      'national', 'province', 'district', 'subdistrict', 'village',
      'institution', 'individual', 'other'
    )),
  time_frequency text not null default 'irregular'
    check (time_frequency in (
      'daily', 'monthly', 'quarterly', 'annual', 'cross_section',
      'panel', 'irregular'
    )),
  reference_period_start date,
  reference_period_end date,
  collection_method text,
  data_classification text not null default 'public_aggregate'
    check (data_classification in (
      'public_aggregate', 'public_deidentified', 'restricted'
    )),
  privacy_review_status text not null default 'pending'
    check (privacy_review_status in (
      'not_required', 'pending', 'passed', 'failed'
    )),
  publication_status text not null default 'draft'
    check (publication_status in (
      'draft', 'in_review', 'approved', 'archived'
    )),
  file_format text,
  row_count bigint check (row_count is null or row_count >= 0),
  variable_count integer check (variable_count is null or variable_count >= 0),
  checksum_sha256 text
    check (checksum_sha256 is null or checksum_sha256 ~ '^[0-9a-fA-F]{64}$'),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint datasets_reference_period_check check (
    reference_period_start is null
    or reference_period_end is null
    or reference_period_end >= reference_period_start
  )
);

create index if not exists datasets_source_id_idx
  on public.datasets (source_id);
create index if not exists datasets_status_idx
  on public.datasets (publication_status, data_classification);
create index if not exists datasets_subject_area_idx
  on public.datasets (subject_area);

-- -----------------------------------------------------------------------------
-- 5. Variable dictionary (MS-Var support)
-- -----------------------------------------------------------------------------

create table if not exists public.dataset_variables (
  id uuid primary key default gen_random_uuid(),
  dataset_id uuid not null references public.datasets (id) on delete cascade,
  variable_name text not null,
  label text not null,
  definition text,
  data_type text not null default 'text'
    check (data_type in (
      'text', 'integer', 'numeric', 'boolean', 'date', 'datetime',
      'categorical', 'geometry', 'json'
    )),
  measurement_level text
    check (measurement_level is null or measurement_level in (
      'nominal', 'ordinal', 'interval', 'ratio', 'identifier', 'other'
    )),
  unit text,
  valid_values jsonb not null default '[]'::jsonb,
  missing_value_codes jsonb not null default '[]'::jsonb,
  confidentiality_level text not null default 'internal'
    check (confidentiality_level in ('public', 'internal', 'restricted')),
  is_direct_identifier boolean not null default false,
  is_quasi_identifier boolean not null default false,
  is_personal_data boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dataset_variables_unique_name unique (dataset_id, variable_name)
);

create index if not exists dataset_variables_dataset_id_idx
  on public.dataset_variables (dataset_id);

-- -----------------------------------------------------------------------------
-- 6. Indicator registry (MS-Ind support)
-- -----------------------------------------------------------------------------

create table if not exists public.indicators (
  id uuid primary key default gen_random_uuid(),
  indicator_code text not null unique
    check (indicator_code ~ '^[A-Z0-9][A-Z0-9_.-]{1,79}$'),
  name text not null,
  definition text not null,
  formula_text text,
  numerator_definition text,
  denominator_definition text,
  unit text,
  target_population text,
  geographic_level text not null default 'other'
    check (geographic_level in (
      'national', 'province', 'district', 'subdistrict', 'village',
      'institution', 'other'
    )),
  reference_period text,
  disaggregation_dimensions text[] not null default '{}',
  dataset_id uuid references public.datasets (id) on delete set null,
  source_url text,
  publication_status text not null default 'draft'
    check (publication_status in ('draft', 'approved', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists indicators_status_idx
  on public.indicators (publication_status);
create index if not exists indicators_dataset_id_idx
  on public.indicators (dataset_id);

-- -----------------------------------------------------------------------------
-- 7. Data quality audit registry
-- Stores QA summaries and metadata only; it is not a raw-data repository.
-- -----------------------------------------------------------------------------

create table if not exists public.data_quality_audits (
  id uuid primary key default gen_random_uuid(),
  dataset_id uuid not null references public.datasets (id) on delete cascade,
  audit_type text not null
    check (audit_type in (
      'schema', 'completeness', 'duplicates', 'validity', 'consistency',
      'privacy', 'import', 'manual', 'other'
    )),
  status text not null default 'queued'
    check (status in ('queued', 'running', 'passed', 'warning', 'failed')),
  total_rows bigint check (total_rows is null or total_rows >= 0),
  checked_rows bigint check (checked_rows is null or checked_rows >= 0),
  missing_cells bigint check (missing_cells is null or missing_cells >= 0),
  duplicate_rows bigint check (duplicate_rows is null or duplicate_rows >= 0),
  invalid_values bigint check (invalid_values is null or invalid_values >= 0),
  summary text,
  findings jsonb not null default '{}'::jsonb,
  run_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists data_quality_audits_dataset_idx
  on public.data_quality_audits (dataset_id, created_at desc);

-- -----------------------------------------------------------------------------
-- 8. Metadata change log
-- Trigger payloads contain catalogue metadata only. Do not put case-level PII
-- or victim/suspect identifiers in these metadata tables.
-- -----------------------------------------------------------------------------

create table if not exists public.metadata_audit_log (
  id bigint generated always as identity primary key,
  entity_table text not null
    check (entity_table in (
      'data_sources', 'datasets', 'dataset_variables', 'indicators'
    )),
  entity_id uuid not null,
  operation text not null check (operation in ('INSERT', 'UPDATE', 'DELETE')),
  old_record jsonb,
  new_record jsonb,
  changed_by uuid references auth.users (id) on delete set null,
  changed_at timestamptz not null default now()
);

create index if not exists metadata_audit_log_entity_idx
  on public.metadata_audit_log (entity_table, entity_id, changed_at desc);
create index if not exists metadata_audit_log_changed_at_idx
  on public.metadata_audit_log (changed_at desc);

-- -----------------------------------------------------------------------------
-- 9. Trigger functions and triggers
-- -----------------------------------------------------------------------------

create or replace function public.log_metadata_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_row jsonb;
  v_entity_id uuid;
begin
  if tg_op = 'INSERT' then
    v_new := to_jsonb(new);
    v_row := v_new;
  elsif tg_op = 'UPDATE' then
    v_old := to_jsonb(old);
    v_new := to_jsonb(new);
    v_row := v_new;
  else
    v_old := to_jsonb(old);
    v_row := v_old;
  end if;

  v_entity_id := nullif(v_row ->> 'id', '')::uuid;

  insert into public.metadata_audit_log (
    entity_table, entity_id, operation, old_record, new_record, changed_by
  ) values (
    tg_table_name, v_entity_id, tg_op, v_old, v_new, auth.uid()
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

-- updated_at triggers
drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists data_sources_set_updated_at on public.data_sources;
create trigger data_sources_set_updated_at
before update on public.data_sources
for each row execute function public.set_updated_at();

drop trigger if exists datasets_set_updated_at on public.datasets;
create trigger datasets_set_updated_at
before update on public.datasets
for each row execute function public.set_updated_at();

drop trigger if exists dataset_variables_set_updated_at on public.dataset_variables;
create trigger dataset_variables_set_updated_at
before update on public.dataset_variables
for each row execute function public.set_updated_at();

drop trigger if exists indicators_set_updated_at on public.indicators;
create trigger indicators_set_updated_at
before update on public.indicators
for each row execute function public.set_updated_at();

drop trigger if exists data_quality_audits_set_updated_at on public.data_quality_audits;
create trigger data_quality_audits_set_updated_at
before update on public.data_quality_audits
for each row execute function public.set_updated_at();

-- Append-only metadata audit triggers
drop trigger if exists data_sources_metadata_audit on public.data_sources;
create trigger data_sources_metadata_audit
after insert or update or delete on public.data_sources
for each row execute function public.log_metadata_change();

drop trigger if exists datasets_metadata_audit on public.datasets;
create trigger datasets_metadata_audit
after insert or update or delete on public.datasets
for each row execute function public.log_metadata_change();

drop trigger if exists dataset_variables_metadata_audit on public.dataset_variables;
create trigger dataset_variables_metadata_audit
after insert or update or delete on public.dataset_variables
for each row execute function public.log_metadata_change();

drop trigger if exists indicators_metadata_audit on public.indicators;
create trigger indicators_metadata_audit
after insert or update or delete on public.indicators
for each row execute function public.log_metadata_change();

-- -----------------------------------------------------------------------------
-- 10. Row Level Security
-- Public visitors may read only approved, public and privacy-reviewed metadata.
-- Public registry rows intentionally omit creator IDs and storage object paths.
-- Only authenticated curator/admin profiles may write governance records.
-- -----------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.data_sources enable row level security;
alter table public.datasets enable row level security;
alter table public.dataset_variables enable row level security;
alter table public.indicators enable row level security;
alter table public.data_quality_audits enable row level security;
alter table public.metadata_audit_log enable row level security;

-- Profiles
drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin
on public.profiles for select to authenticated
using (id = auth.uid() or public.is_platform_admin());

drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update
on public.profiles for update to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

-- Data sources
drop policy if exists data_sources_public_read on public.data_sources;
create policy data_sources_public_read
on public.data_sources for select to anon, authenticated
using (
  (visibility = 'public' and is_active)
  or public.is_curator_or_admin()
);

drop policy if exists data_sources_curator_manage on public.data_sources;
create policy data_sources_curator_manage
on public.data_sources for all to authenticated
using (public.is_curator_or_admin())
with check (public.is_curator_or_admin());

-- Dataset catalogue
drop policy if exists datasets_public_read on public.datasets;
create policy datasets_public_read
on public.datasets for select to anon, authenticated
using (
  (
    publication_status = 'approved'
    and data_classification in ('public_aggregate', 'public_deidentified')
    and privacy_review_status in ('passed', 'not_required')
  )
  or public.is_curator_or_admin()
);

drop policy if exists datasets_curator_manage on public.datasets;
create policy datasets_curator_manage
on public.datasets for all to authenticated
using (public.is_curator_or_admin())
with check (public.is_curator_or_admin());

-- Variable dictionary
drop policy if exists dataset_variables_public_read on public.dataset_variables;
create policy dataset_variables_public_read
on public.dataset_variables for select to anon, authenticated
using (
  confidentiality_level = 'public'
  and not is_direct_identifier
  and not is_quasi_identifier
  and not is_personal_data
  and exists (
    select 1
    from public.datasets d
    where d.id = dataset_variables.dataset_id
      and d.publication_status = 'approved'
      and d.data_classification in ('public_aggregate', 'public_deidentified')
      and d.privacy_review_status in ('passed', 'not_required')
  )
  or public.is_curator_or_admin()
);

drop policy if exists dataset_variables_curator_manage on public.dataset_variables;
create policy dataset_variables_curator_manage
on public.dataset_variables for all to authenticated
using (public.is_curator_or_admin())
with check (public.is_curator_or_admin());

-- Indicator registry
drop policy if exists indicators_public_read on public.indicators;
create policy indicators_public_read
on public.indicators for select to anon, authenticated
using (publication_status = 'approved' or public.is_curator_or_admin());

drop policy if exists indicators_curator_manage on public.indicators;
create policy indicators_curator_manage
on public.indicators for all to authenticated
using (public.is_curator_or_admin())
with check (public.is_curator_or_admin());

-- Quality audits are restricted to curator/admin users.
drop policy if exists data_quality_audits_curator_access on public.data_quality_audits;
create policy data_quality_audits_curator_access
on public.data_quality_audits for all to authenticated
using (public.is_curator_or_admin())
with check (public.is_curator_or_admin());

-- Metadata audit log is readable only by platform admins.
drop policy if exists metadata_audit_log_admin_read on public.metadata_audit_log;
create policy metadata_audit_log_admin_read
on public.metadata_audit_log for select to authenticated
using (public.is_platform_admin());

-- -----------------------------------------------------------------------------
-- 11. Grants (RLS remains the row-level security boundary)
-- -----------------------------------------------------------------------------

grant usage on schema public to anon, authenticated;

grant select on public.data_sources, public.datasets,
  public.dataset_variables, public.indicators to anon, authenticated;

grant insert, update, delete on public.data_sources, public.datasets,
  public.dataset_variables, public.indicators to authenticated;

grant select, update on public.profiles to authenticated;
grant select, insert, update on public.data_quality_audits to authenticated;
grant select on public.metadata_audit_log to authenticated;

grant execute on function public.is_curator_or_admin() to anon, authenticated;
grant execute on function public.is_platform_admin() to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 12. Documentation comments
-- -----------------------------------------------------------------------------

comment on table public.data_sources is
  'Registry of official and research sources; MS-Keg supporting metadata.';
comment on table public.datasets is
  'Dataset catalogue metadata only. Do not store person-level crime records here.';
comment on table public.dataset_variables is
  'Variable dictionary; MS-Var supporting metadata and privacy classification.';
comment on table public.indicators is
  'Indicator registry; MS-Ind supporting definitions, formulae and units.';
comment on table public.data_quality_audits is
  'Quality-control summaries and findings; no raw case-level records.';
comment on table public.metadata_audit_log is
  'Append-only change history for governance metadata.';
comment on table public.profiles is
  'Application profiles. New accounts default to viewer; role promotion is administrator-controlled.';

commit;
