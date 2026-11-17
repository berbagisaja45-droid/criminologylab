# Criminology Lab — Supabase Foundation

Project reference: `rurfluvlcnexxuwfngaj`  
Supabase project: `Criminology Lab`  
GitHub repository: `berbagisaja45-droid/criminologylab`

This folder introduces version-controlled Supabase configuration and the first governance migration. It does **not** connect the GitHub Pages website to Supabase and does **not** apply SQL to the hosted database by itself.

## Contents

- `config.toml` — Supabase CLI project and local API/database configuration.
- `migrations/20261117120000_criminology_governance_foundation.sql` — additive schema for source, dataset, variable, indicator, profile, quality-audit, and metadata-audit registries, plus RLS policies.
- `.gitignore` — excludes local Supabase state and environment secrets.

## Important: existing hosted project

The Supabase project already exists. Before applying this migration, first capture its current hosted schema so that any tables previously created from the Dashboard or SQL Editor are represented in version control.

From the repository root, after installing the Supabase CLI:

```bash
supabase login
supabase link --project-ref rurfluvlcnexxuwfngaj
supabase db pull --remote
```

Review the generated `*_remote_schema.sql` migration and the existing remote migration history. Ensure the remote baseline migration is ordered **before** `20261117120000_criminology_governance_foundation.sql`. If timestamp ordering is not correct, rename the governance migration to a timestamp later than the captured baseline before running any push.

Then validate locally:

```bash
supabase start
supabase db reset
supabase migration list
```

Only after reviewing the diff and confirming the remote baseline is correct should an administrator deploy the migrations:

```bash
supabase db push --remote
```

Do not run `supabase db reset` against the hosted/production database. Do not push this migration before the remote schema baseline has been captured and reviewed.

## Schema overview

| Table | Purpose |
|---|---|
| `public.profiles` | Auth-linked profile and role (`viewer`, `curator`, `admin`) |
| `public.data_sources` | Source registry and provenance metadata (MS-Keg support) |
| `public.datasets` | Dataset catalogue and classification metadata (MS-Keg support) |
| `public.dataset_variables` | Variable definitions, units, valid/missing codes and privacy flags (MS-Var support) |
| `public.indicators` | Indicator definitions, formulae, numerator/denominator and units (MS-Ind support) |
| `public.data_quality_audits` | Quality-check summaries and structured findings |
| `public.metadata_audit_log` | Append-only metadata change history |

## Security model

- New Auth users receive the `viewer` role automatically.
- Only `curator` and `admin` roles can create or modify governance records.
- Public visitors can read only approved public metadata and variables that have passed privacy review. Direct identifiers, quasi-identifiers, personal-data variables, creator IDs and storage object paths are not exposed in the public catalogue.
- Quality-audit records are restricted to curators and administrators; metadata audit logs are restricted to administrators.
- This migration does not create public storage buckets and does not expose raw person-level crime records.
- Never place Supabase secret/service-role keys in `index.html`, GitHub, or this folder. A browser client may use only a publishable/anon key with RLS enabled.

## Bootstrap the first administrator

After the intended administrator has registered through Supabase Auth and a matching row exists in `public.profiles`, run this once in the Supabase SQL Editor, replacing the placeholder with the verified account email:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('REPLACE_WITH_ADMIN_EMAIL');
```

Do not expose this SQL as a public website feature. Only a trusted project owner should execute it.

## Privacy boundary

This first schema is intended for source metadata, dataset catalogues, aggregate statistics and de-identified analytical metadata. Do not upload victims', witnesses', suspects' or children’s names, NIK, addresses, case documents, investigation materials, or other identifiable case-level data into the public website or public tables.

## Next phase

After the remote schema baseline is captured, test this migration locally, then connect the frontend using a publishable Supabase key and role-aware RLS. Keep schema changes in migration files once this workflow is established.
