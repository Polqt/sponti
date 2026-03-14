# Supabase Guide

This project keeps Supabase database changes in `supabase/migrations` and seed data in `supabase/seed.sql`.

## Files

- `supabase/migrations/*.sql`: schema, policies, triggers, and RPC functions
- `supabase/seed.sql`: initial location data
- `supabase/config.toml`: CLI config, including the configured seed path

`supabase/config.toml` already enables seeding and points to `./seed.sql`.

## If tables are already migrated

If your hosted Supabase tables are already up to date and you just want to apply the seed file, use the Supabase CLI from the project root:

```powershell
supabase login
supabase link --project-ref <your-project-ref>
supabase db push --include-seed
```

Notes:

- This does not require Docker when pushing to a hosted Supabase project.
- `db push` skips migrations already recorded on the remote project and applies any remaining ones.
- `--include-seed` also runs the SQL files listed in `supabase/config.toml`.

## Seed only without pushing migrations again

If you want a one-off seed run against the hosted database without using `db push`, run the seed file with `psql`:

```powershell
psql "<your-postgres-connection-string>" -f supabase/seed.sql
```

You can copy the connection string from Supabase Dashboard -> Connect.

If `psql` is not installed, the fallback is:

1. Open `supabase/seed.sql`.
2. Copy the SQL.
3. Run it in Supabase Dashboard -> SQL Editor.

## Important warning about duplicates

`supabase/seed.sql` is currently insert-only. Running it more than once will create duplicate rows in `public.locations`.

Before re-running the seed in an existing environment, choose one approach:

- Run it only once on a fresh database.
- Manually clear seeded rows first.
- Refactor the seed script later to be idempotent with `ON CONFLICT` or an upsert strategy.

## Local vs hosted workflow

Use hosted-only commands if you do not use Docker:

- Hosted project: `supabase db push --include-seed`
- Hosted project, seed only: `psql "...connection string..." -f supabase/seed.sql`

These local commands are the ones that depend on the local Supabase stack and typically Docker:

- `supabase start`
- `supabase db reset`

## Recommended command for this repo

Because you already migrated the tables, the best next step is usually:

```powershell
supabase db push --include-seed
```

If the migrations are already applied remotely, this is the simplest way to run the configured seed file.

## Verify the seed worked

Run this in Supabase SQL Editor:

```sql
select category, count(*)
from public.locations
group by category
order by category;
```

And a quick total:

```sql
select count(*) from public.locations;
```

## App configuration checklist

- Set `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_KEY` in `.env.local`
- Confirm the auth redirect scheme matches `io.supabase.sponti://login-callback/`
- Confirm storage buckets exist:
  - `avatars`
  - `location-photos`

Related docs:

- [Environment variables](./ENV_VARIABLES.md)
- [Database schema](./DATABASE_SCHEMA.md)
- [Supabase storage for legal pages](./legal/SETUP_WITH_SUPABASE_STORAGE.md)

Official Supabase references:

- https://supabase.com/docs/guides/deployment/database-migrations
- https://supabase.com/docs/guides/local-development/seeding-your-database
- https://supabase.com/docs/guides/local-development/cli/getting-started
