# Feature Implementation Plan

## Goal

Modernize Sponti's discovery stack without breaking current behavior:

- Move search, ranking, and recommendation logic closer to Supabase SQL/RPC.
- Replace large full-list reads with cursor-based pagination.
- Stop streaming whole collections only to compute counts.
- Introduce a derived metrics layer for trending, popularity, and live signals.
- Standardize app-side architecture around Riverpod.
- Add a safe rollout path with feature flags and targeted tests.

---

## Current Status

### Already Landed In Codebase

- `FEATURE_RANKED_SEARCH`
- `FEATURE_CURSOR_PAGINATION`
- `FEATURE_LOCATION_METRICS`
- shared `StorageUploadService` for review/check-in photo uploads
- direct "my review for this location" repository contract
- removal of the duplicate unused `surprise_me` feature surface
- removal of runtime `get_it` bootstrap from app startup
- additive location pagination contract
- additive ranked search RPC contract
- additive `location_metrics_daily` materialized view

### Default Rollout State

All new behavior remains opt-in. Existing screens keep using the stable path unless the related feature flag is enabled.

---

## Phase 1: Safety And Rollout Backbone

### Objective

Ship all risky changes as additive infrastructure first.

### Work

- add feature flags in `.env`
- keep legacy search as the default runtime path
- fall back to legacy search if ranked RPC fails
- avoid replacing existing RPCs in-place
- add focused tests around the new contracts before UI cutover

### Exit Criteria

- app behavior is unchanged with all flags off
- ranked search can be enabled per environment
- new SQL objects deploy cleanly without forcing client cutover

---

## Phase 2: Search And Ranking Pipeline

### Objective

Use one deterministic server-side ranking pipeline for discovery search.

### New RPC

`search_locations_ranked(search_query, viewer_lat, viewer_lng, limit_count)`

### Ranking Inputs

- `ts_rank` from `locations.fts`
- trigram similarity on `name`, `address`, and `landmark`
- popularity from favorites and recent activity
- proximity using optional viewer coordinates
- open-now boost using `open_time`, `close_time`, and `days_open`
- user-history boosts from the viewer's favorites and check-ins

### App Rollout

1. Deploy the new migration.
2. Keep `FEATURE_RANKED_SEARCH=false`.
3. Enable it in staging.
4. Compare ranked and legacy results for the same queries.
5. Enable in production only after query quality is acceptable.

### Follow-Up Work

- expose ranking debug metadata in a staging-only admin screen
- add query analytics for poor-result searches
- add recommendation RPCs for surprise/crawl planning using the same score primitives

---

## Phase 3: Scalability

### Objective

Remove `1000`-row assumptions and prepare the app for larger city datasets.

### Cursor Pagination

New app contracts:

- `LocationPageCursor`
- `LocationPage`
- `LocationRepository.getLocationsPage(...)`

### Implementation Notes

- cursor is based on `created_at` plus `id`
- ordering stays deterministic with `created_at DESC, id DESC`
- legacy `getAllLocations()` remains for existing screens during migration

### Data Signals

New derived layer:

- `location_metrics_daily` materialized view

This is the base for:

- recent check-in momentum
- recent review activity
- favorite velocity
- future "busy now", "picking up", and "quiet" badges

### Next Scalability Tasks

- switch discovery/explore/search feeds to paginated fetches
- add a refresh policy or scheduled refresh for `location_metrics_daily`
- introduce summarized snapshot RPCs for location detail instead of collection-count streams
- add pagination to favorites and my-check-ins once volume justifies it

---

## Phase 4: Maintainability

### Objective

Reduce architecture drift and duplicated code.

### Direction

- Riverpod is the runtime DI source of truth
- keep repository contracts consistent across features
- centralize cross-feature services in `lib/core`

### Completed

- shared upload flow extracted to `StorageUploadService`
- duplicate `surprise_me` surface removed
- runtime `get_it` bootstrap removed from `main.dart`

### Remaining Cleanup

- delete old unused `get_it` / `injectable` files after one stable release
- move feature folders toward explicit `data`, `domain`, and `presentation` boundaries
- align repository APIs so "my item" lookups do not fetch entire collections
- move more cross-cutting helpers into `core/services`, `core/models`, or `core/providers`

---

## Phase 5: Quality Gates

### Priority Test Coverage

#### Repository Tests

- ranked search fallback behavior
- direct "my review" repository reads
- pagination cursor encoding/decoding

#### Provider Tests

- `searchResultsProvider` uses ranked search only when the flag is enabled
- ranked search falls back to legacy search if RPC fails
- search cache keys stay isolated between legacy and ranked modes

#### SQL Contract Tests

- `search_locations_ranked` returns ordered rows for representative queries
- `location_metrics_daily` refresh produces expected daily aggregates
- ranking behavior remains deterministic for fixed fixtures

### Current Local Test Targets Added

- `test/core/services/storage_upload_service_test.dart`
- `test/features/locations/model/location_query_test.dart`
- `test/features/search/viewmodel/search_viewmodel_test.dart`

---

## Rollout Checklist

### Deploy Order

1. deploy Supabase migrations
2. deploy app with all feature flags off
3. verify legacy behavior still matches production
4. enable `FEATURE_RANKED_SEARCH` in staging
5. compare search quality and response shape
6. enable `FEATURE_LOCATION_METRICS` consumers only after metrics refresh strategy is ready
7. migrate feeds from `getAllLocations()` to `getLocationsPage()` in small slices

### Rollback Strategy

- turn feature flags off
- keep legacy providers and RPCs available until at least one stable release after cutover
- do not remove legacy search or list-fetch paths until ranking and pagination are verified in production

---

## Recommended Next Implementation Slice

1. wire a staging-only debug switch or environment flag review flow for ranked search
2. migrate one safe screen to cursor pagination first, preferably search or discovery
3. replace remaining collection-count streams with location-row or snapshot-based reads
4. add a recommendation RPC for "Surprise Me 2.0" built on top of the ranked search primitives
