# Critical Workflows: Sponti

**Purpose**: Document non-obvious setup steps and order-sensitive workflows to prevent getting stuck
**Date**: 2026-03-08

---

## ⚠️ Supabase Database Setup Order (Phase 1)

**STOP! Read this before creating tables.**

**Context**: Tables have foreign key dependencies, triggers reference tables that must exist first, and RLS policies need to be enabled in the right order.

**Order matters:**
1. Enable extensions first (`uuid-ossp`, `postgis`, `pg_trgm`)
2. Create `profiles` table (referenced by all other tables)
3. Create auth trigger `on_auth_user_created` → inserts into profiles
4. Create `locations` table
5. Create `reviews` table (references profiles + locations)
6. Create `check_ins` table (references profiles + locations)
7. Create `favorites` table (references profiles + locations)
8. Create `suggestions` table (references profiles)
9. Create `location_photos` table (references profiles + locations)
10. Create RPC functions (reference locations table)
11. Enable RLS on ALL tables
12. Create RLS policies
13. Create storage buckets + storage policies

**Why this order**: Foreign keys reference `profiles` and `locations` — they must exist first. Triggers on `reviews` and `check_ins` update `locations` and `profiles` counters — those columns must exist. RLS must be enabled after tables are created but before policies.

**Common Mistake**: Creating `reviews` before `profiles` → FK constraint fails.

**Fix if broken**: Drop dependent tables, recreate in correct order.

---

## ⚠️ PostGIS Extension for Nearby Queries (Phase 1)

**STOP! Read before implementing `get_nearby_locations`.**

**Context**: The `get_nearby_locations` RPC uses PostGIS geography functions. PostGIS must be enabled before creating the function.

**Steps:**
```sql
-- 1. Enable PostGIS (run in SQL editor)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Verify it works
SELECT PostGIS_Version();

-- 3. Then create the RPC function that uses ST_Distance, ST_DWithin
```

**Common Mistake**: Creating the RPC function before enabling PostGIS → function creation fails with "function ST_Distance does not exist".

**Fix**: Run `CREATE EXTENSION IF NOT EXISTS postgis;` and then re-run the function definition.

---

## ⚠️ Auth Trigger for Profile Auto-Creation (Phase 1)

**STOP! Read before testing authentication.**

**Context**: When a user signs up via Google/Facebook OAuth, Supabase creates an entry in `auth.users`. We need a database trigger to auto-create a corresponding row in `profiles`.

**Steps:**
```sql
-- 1. Create the function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture', '')
  );
  RETURN NEW;
END;
$$;

-- 2. Create the trigger
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

**Why `SECURITY DEFINER`**: The trigger runs as the function owner (postgres), bypassing RLS. Without this, the insert into `profiles` would fail because the user doesn't have permission yet during signup.

**Common Mistake**: Forgetting `SECURITY DEFINER` → new users can't create profiles → auth works but profile is null.

**Fix**: Alter the function to add `SECURITY DEFINER`, or manually insert missing profile rows.

---

## ⚠️ RLS Policy Design for Favorites (Phase 6)

**Context**: Unlike reviews (public), favorites are private. Users should only see their own favorites.

**Key Policy:**
```sql
-- Users can only see their own favorites
CREATE POLICY "Users can view own favorites" ON favorites
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own favorites
CREATE POLICY "Users can insert own favorites" ON favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own favorites
CREATE POLICY "Users can delete own favorites" ON favorites
  FOR DELETE USING (auth.uid() = user_id);
```

**Common Mistake**: Allowing public SELECT on favorites → privacy leak. Unlike reviews, favorites are personal data.

---

## ⚠️ Review Rating Recalculation Trigger (Phase 7)

**Context**: When a review is created or deleted, the location's `rating` and `review_count` must be updated. Using a trigger ensures consistency.

```sql
CREATE OR REPLACE FUNCTION update_location_rating()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.locations SET
      rating = (SELECT COALESCE(AVG(r.rating), 0) FROM public.reviews r WHERE r.location_id = NEW.location_id),
      review_count = (SELECT COUNT(*) FROM public.reviews r WHERE r.location_id = NEW.location_id)
    WHERE id = NEW.location_id;

    UPDATE public.profiles SET total_reviews = total_reviews + 1 WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations SET
      rating = (SELECT COALESCE(AVG(r.rating), 0) FROM public.reviews r WHERE r.location_id = OLD.location_id),
      review_count = (SELECT COUNT(*) FROM public.reviews r WHERE r.location_id = OLD.location_id)
    WHERE id = OLD.location_id;

    UPDATE public.profiles SET total_reviews = GREATEST(total_reviews - 1, 0) WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER on_review_change
  AFTER INSERT OR DELETE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_location_rating();
```

**Common Mistake**: Forgetting to handle DELETE → rating never decreases when reviews are removed.

---

## ⚠️ GoRouter Shell Route Migration (Phase 13)

**Context**: The current `app_router.dart` uses flat routes (not nested under a `ShellRoute`). This means the bottom navigation bar doesn't persist when navigating between tabs. Phase 13 needs to migrate to `ShellRoute`.

**Current (broken for nav persistence):**
```dart
GoRoute(path: '/location', builder: ...),
GoRoute(path: '/discovery', builder: ...),
```

**Correct:**
```dart
ShellRoute(
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    GoRoute(path: '/location', builder: ...),
    GoRoute(path: '/discovery', builder: ...),
    GoRoute(path: '/explore', builder: ...),
    GoRoute(path: '/favorites', builder: ...),
    GoRoute(path: '/profile', builder: ...),
  ],
),
// Full-screen routes OUTSIDE the shell
GoRoute(path: '/locations/:id', parentNavigatorKey: _rootNavigatorKey, builder: ...),
GoRoute(path: '/search', parentNavigatorKey: _rootNavigatorKey, builder: ...),
```

**Why**: Without `ShellRoute`, navigating to `/discovery` replaces the entire screen including the bottom nav bar. With `ShellRoute`, the bottom nav bar persists and only the body swaps.

**Common Mistake**: Putting full-screen routes (detail, search, surprise) inside the shell → they show the bottom nav bar when they shouldn't.

---

## ⚠️ Video Onboarding Testing Reset (Must Remove)

**Context**: `video_onboarding_screen.dart` line 24-31 contains `_resetOnboardingForTesting()` which resets onboarding completion on every launch. This must be removed before any release.

**File**: `lib/features/onboarding/presentation/screens/video_onboarding_screen.dart`

```dart
// TEMPORARY: Reset onboarding for testing
// Remove this after testing is complete
_resetOnboardingForTesting();  // ← DELETE THIS CALL in initState()

Future<void> _resetOnboardingForTesting() async {  // ← DELETE THIS METHOD
  final datasource = OnboardingLocalDatasourceImpl();
  await datasource.resetOnboarding();
}
```

**Impact if not removed**: Users see the onboarding video every time they open the app.

---

## Quick Checklist

Before starting each phase, check if it has critical workflows:

- [x] Phase 1: Database Setup Order, PostGIS Extension, Auth Trigger (see above)
- [ ] Phase 2: No critical workflows (just data entry)
- [ ] Phase 3: No critical workflows
- [ ] Phase 4: No critical workflows
- [ ] Phase 5: Location permission handling on iOS requires `NSLocationWhenInUseUsageDescription` in Info.plist
- [x] Phase 6: RLS Policy for Favorites privacy (see above)
- [x] Phase 7: Review Rating Trigger (see above)
- [ ] Phase 8: Check-in proximity validation (client-side, not a DB concern)
- [ ] Phase 9: Avatar upload needs storage policies
- [ ] Phase 10: No critical workflows
- [ ] Phase 11: No critical workflows
- [ ] Phase 12: No critical workflows
- [x] Phase 13: GoRouter ShellRoute Migration (see above)
- [x] Phase 14: Remove onboarding testing reset (see above)
