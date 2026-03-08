# Implementation Phases: Sponti

**Project Type**: Mobile App (Flutter)
**Stack**: Flutter 3.x + Supabase (Auth, Database, Storage, Realtime) + Riverpod + GoRouter + flutter_map
**Architecture**: Clean Architecture (domain/data/presentation) with GetIt DI
**Estimated Total**: ~85-100 hours (~12-14 sessions)

---

## Current State (What's Already Built)

### Completed
- **Project scaffolding**: Flutter project structure, Clean Architecture folders
- **Onboarding**: Video onboarding screen with Hive-persisted completion state
- **Authentication**: Google + Facebook OAuth via Supabase (full data → domain → presentation)
- **Locations data layer**: Entity, Model (fromJson/toJson), Remote + Local datasources, Repository with offline cache fallback, 7 use cases (CRUD + nearby + search + filter), Riverpod providers with filter/search/nearby/mutations
- **Shell/Navigation**: MainShell with 5-tab bottom nav + center "Surprise Me" FAB (routes commented out)
- **Theme**: Full Material 3 theme (brand colors, category colors, all widget themes)
- **Core widgets**: AppButton, AppBadge, AppEmptyState, AppSectionHeader, ImagePlaceholder, ShimmerBox
- **Constants**: API table names, RPC function names, storage buckets, route paths

### Needs Building
- Supabase database (all tables, RLS, RPC functions)
- All UI screens (location list, detail, map, search, profile, favorites, surprise)
- Reviews feature (full stack)
- Check-in feature (full stack)
- Favorites feature (full stack)
- Profile feature (full stack)
- Suggestions/submit spot feature (full stack)
- Photo gallery feature
- Seed data and content strategy

---

## Phase 1: Supabase Database Setup
**Type**: Database
**Estimated**: 3-4 hours
**Files**: SQL migrations (run in Supabase SQL editor or via CLI)

### Tasks
- [ ] Create `profiles` table (id references auth.users, username, full_name, avatar_url, bio, total_check_ins, total_reviews, created_at, updated_at)
- [ ] Create `locations` table with all columns matching `LocationModel.fromJson` (id UUID, name, description, category, latitude, longitude, address, landmark, price_range, photos JSONB, tags JSONB, rating, review_count, check_in_count, is_hidden_gem, is_verified, has_wifi, is_pet_friendly, has_parking, open_time, close_time, days_open JSONB, special_hours_note, contact_number, website_url, instagram_handle, submitted_by, created_at, updated_at)
- [ ] Create `reviews` table (id, location_id FK, user_id FK, rating 1-5, comment, photos JSONB, created_at, updated_at)
- [ ] Create `check_ins` table (id, location_id FK, user_id FK, note, photo_url, created_at)
- [ ] Create `favorites` table (id, location_id FK, user_id FK, created_at) with unique constraint on (location_id, user_id)
- [ ] Create `suggestions` table (id, user_id FK, name, description, category, address, latitude, longitude, reason, status enum, created_at)
- [ ] Create `location_photos` table (id, location_id FK, user_id FK, photo_url, caption, created_at)
- [ ] Enable PostGIS extension and create `get_nearby_locations` RPC function
- [ ] Create `search_locations` RPC function using full-text search (ts_vector)
- [ ] Create `get_location_with_stats` RPC function (joins reviews/check-ins aggregates)
- [ ] Set up Row Level Security (RLS) policies for all tables
- [ ] Create `on_auth_user_created` trigger to auto-create profile row
- [ ] Create R2/Storage buckets: `location-photos`, `avatars`
- [ ] Create database indexes (category, rating, location for geo queries)

### Verification Criteria
- [ ] All tables visible in Supabase dashboard with correct columns and types
- [ ] RLS policies enforce: anyone can read locations/reviews, only authenticated users can write, users can only modify their own data
- [ ] `get_nearby_locations` RPC returns locations sorted by distance with `distance_km` field
- [ ] `search_locations` RPC performs text search on name + description + tags
- [ ] New auth signup auto-creates a profile row
- [ ] Storage buckets accept image uploads with correct policies

### Exit Criteria
All Supabase tables, functions, policies, and storage buckets are created and verified via the Supabase dashboard. The Flutter app can connect and perform basic queries.

---

## Phase 2: Seed Data & Content Strategy
**Type**: Database
**Estimated**: 3-4 hours
**Files**: `supabase/seed.sql`, potentially a JSON file for bulk import

### Tasks
- [ ] Research and compile 30-50 real Bacolod locations across all 6 categories (food, coffee, nature, nightlife, arts, activities)
- [ ] Include mix of well-known spots and hidden gems
- [ ] Gather accurate data: names, descriptions, addresses, coordinates (from Google Maps), operating hours, price ranges, photos, tags
- [ ] Write a `seed.sql` script to insert all locations
- [ ] Add 5-10 sample reviews per popular location
- [ ] Tag at least 10 locations as `is_hidden_gem = true`
- [ ] Include amenity data (wifi, pet-friendly, parking) where known
- [ ] Upload location photos to Supabase storage
- [ ] Run seed script and verify data appears correctly

### Verification Criteria
- [ ] At least 30 locations in database across all 6 categories
- [ ] Each location has: name, description, coordinates, address, category, at least 1 photo URL, price range
- [ ] At least 10 hidden gems are marked
- [ ] Sample reviews exist with ratings
- [ ] Photos load from storage bucket URLs

### Exit Criteria
Database is populated with enough real data to build and test all UI screens. All categories have representation.

---

## Phase 3: Location List Screen (Spots Tab)
**Type**: UI
**Estimated**: 5-6 hours
**Files**: `lib/features/locations/presentation/screens/location_screen.dart`, `lib/features/locations/presentation/widgets/location_card.dart`, `lib/features/locations/presentation/widgets/tags_selector.dart`, `lib/features/locations/presentation/widgets/category_chip_bar.dart` (new)

### File Map
- `location_screen.dart` (~200 lines) — Main spots list with category filter bar, search input, filter chips, pull-to-refresh, paginated list
- `location_card.dart` (existing, enhance) — Location card with photo, name, category badge, rating, distance, price, open/closed tag
- `tags_selector.dart` (existing, enhance) — Tag filter chips
- `category_chip_bar.dart` (~80 lines, new) — Horizontal scrollable category filter bar using `LocationCategory` enum

### Data Flow
```
LocationScreen
  → watches locationsProvider (AsyncNotifier)
  → watches locationFilterProvider
  → LocationFilterNotifier.toggleCategory / toggleOpenNow / etc.
  → LocationsNotifier._fetch → GetAllLocationsUseCase or FilterByCategoryUseCase
  → LocationRemoteDataSource → Supabase
```

### Tasks
- [ ] Replace placeholder `LocationScreen` with full implementation
- [ ] Add horizontal scrollable category chip bar (Food, Cafes, Stroll, Nightlife, Arts, Fun)
- [ ] Add search bar at the top with debounced text input
- [ ] Add filter chips row (Open Now, Hidden Gems, Pet Friendly, WiFi)
- [ ] Implement `LocationCard` widget (photo with CachedNetworkImage, name, category emoji + color, star rating, distance, price symbol, open/closed badge)
- [ ] Wire up `locationsProvider` and `locationFilterProvider`
- [ ] Implement pull-to-refresh
- [ ] Add pagination (infinite scroll)
- [ ] Show shimmer loading placeholders while data loads
- [ ] Show `AppEmptyState` when no locations match filters
- [ ] Navigate to location detail on card tap

### Verification Criteria
- [ ] Screen loads and displays location cards from Supabase
- [ ] Category chips filter the list correctly
- [ ] Search bar filters by name/description
- [ ] Filter chips (Open Now, Hidden Gems, etc.) work
- [ ] Pull-to-refresh reloads data
- [ ] Shimmer placeholders show during loading
- [ ] Empty state shows when no results
- [ ] Tapping a card navigates to detail screen

### Exit Criteria
Location list screen is fully functional with filtering, searching, pagination, and navigation to detail. All data flows through the existing Clean Architecture providers.

---

## Phase 4: Location Detail Screen
**Type**: UI
**Estimated**: 5-6 hours
**Files**: `lib/features/locations/presentation/screens/location_detail_screen.dart`, `lib/features/locations/presentation/widgets/operating_hours_widget.dart`, `lib/features/locations/presentation/widgets/photo_gallery.dart` (new), `lib/features/locations/presentation/widgets/location_info_section.dart` (new), `lib/features/locations/presentation/widgets/location_action_bar.dart` (new)

### File Map
- `location_detail_screen.dart` (~300 lines) — Full detail view with hero photo, info, actions, reviews section
- `operating_hours_widget.dart` (existing, enhance) — Display open/close times, days, is-open-now indicator
- `photo_gallery.dart` (~100 lines, new) — Horizontal photo carousel with full-screen viewer
- `location_info_section.dart` (~80 lines, new) — Address, distance, price, amenities grid
- `location_action_bar.dart` (~60 lines, new) — Favorite, check-in, share, directions buttons

### Tasks
- [ ] Replace placeholder with full `LocationDetailScreen` using `locationDetailProvider`
- [ ] Hero image section with photo carousel (swipeable, dot indicators)
- [ ] Location name, category badge, rating stars with review count
- [ ] Action bar: Favorite button, Check-in button, Share button (share_plus), Directions button (url_launcher to maps)
- [ ] Info section: address with landmark, distance from user, price range, amenities icons (WiFi, Pet Friendly, Parking)
- [ ] Operating hours widget showing today's hours and open/closed status
- [ ] Description section (expandable if long)
- [ ] Tags section
- [ ] Contact info section (phone, website, Instagram) with tap-to-open
- [ ] "Hidden Gem" badge display
- [ ] Photo gallery section (user-submitted photos)
- [ ] Reviews section placeholder (will be built in Phase 7)
- [ ] Back navigation and app bar with location name

### Verification Criteria
- [ ] Detail screen loads location data from provider
- [ ] Photo carousel swipes between images
- [ ] Share button opens system share sheet with location info
- [ ] Directions button opens external maps app with coordinates
- [ ] Contact links (phone, website, Instagram) open correctly
- [ ] Operating hours display correctly with open/closed indicator
- [ ] Amenity icons display based on location flags
- [ ] Back navigation works

### Exit Criteria
Location detail screen shows all available information about a location with working share, directions, and contact actions. Favorite and check-in buttons are visually present (wired up in later phases).

---

## Phase 5: Map & Discovery Screen
**Type**: UI + Integration
**Estimated**: 6-7 hours
**Files**: `lib/features/discovery/presentation/screens/map_screen.dart`, `lib/features/discovery/presentation/widgets/map_widget.dart`, `lib/features/discovery/presentation/widgets/custom_marker.dart`, `lib/features/discovery/presentation/widgets/category_filter_bar.dart`, `lib/features/discovery/data/datasources/geolocation_datasource.dart`, `lib/features/discovery/data/repositories/map_repository_impl.dart`

### File Map
- `map_screen.dart` (~250 lines) — Full discovery map with filter bar, location permission handling
- `map_widget.dart` (~150 lines) — flutter_map widget with OpenStreetMap tiles centered on Bacolod
- `custom_marker.dart` (~80 lines) — Category-colored markers with emoji icons
- `category_filter_bar.dart` (~60 lines) — Overlay filter bar on map
- `geolocation_datasource.dart` (~80 lines) — Geolocator wrapper for current position
- `map_repository_impl.dart` (~60 lines) — Combines geolocation + location data

### Data Flow
```
MapScreen
  → requests location permission (permission_handler)
  → gets user position (geolocator)
  → watches nearbyLocationsProvider(NearbyParams)
  → renders markers on flutter_map
  → category filter → re-fetches with filter
  → tap marker → show bottom sheet → navigate to detail
```

### Tasks
- [ ] Implement `GeoLocationDataSource` with geolocator (getCurrentPosition, getPositionStream)
- [ ] Implement `MapRepositoryImpl`
- [ ] Implement `MapScreen` with location permission request flow
- [ ] Center map on Bacolod (10.6840, 122.9740) with fallback if no GPS
- [ ] Render location markers using custom colored markers per category
- [ ] Add category filter overlay bar
- [ ] Marker tap → show bottom sheet with location preview card
- [ ] Bottom sheet tap → navigate to location detail
- [ ] "Center on me" floating button
- [ ] Map zoom controls
- [ ] Wire up `nearbyLocationsProvider` and `locationPermissionProvider`

### Verification Criteria
- [ ] Map renders with OpenStreetMap tiles centered on Bacolod
- [ ] Location permission is requested and handled (granted, denied, permanently denied)
- [ ] Markers appear at correct coordinates with category colors
- [ ] Category filter shows/hides markers by category
- [ ] Tapping a marker shows a bottom sheet preview
- [ ] Bottom sheet navigates to location detail
- [ ] "Center on me" button works when location is granted

### Exit Criteria
Interactive map displays all locations as colored markers, supports category filtering, and allows navigation to location details. Location permission flow is handled gracefully.

---

## Phase 6: Favorites Feature
**Type**: Full Stack (Data + UI)
**Estimated**: 4-5 hours
**Files**: `lib/features/favorites/data/datasources/favorites_remote_datasource.dart` (new), `lib/features/favorites/data/repositories/favorites_repository_impl.dart` (new), `lib/features/favorites/domain/entities/favorite.dart` (new), `lib/features/favorites/domain/repositories/favorites_repository.dart` (new), `lib/features/favorites/domain/usecases/` (new, 3 files), `lib/features/favorites/presentation/providers/favorites_provider.dart` (new), `lib/features/favorites/presentation/screens/favorites_screen.dart` (new)

### Tasks
- [ ] Create `Favorite` entity (id, locationId, userId, createdAt)
- [ ] Create `FavoritesRemoteDataSource` (toggle, getAll, checkIsFavorite)
- [ ] Create `FavoritesRepository` interface and implementation
- [ ] Create use cases: ToggleFavoriteUseCase, GetFavoritesUseCase, CheckFavoriteUseCase
- [ ] Create `favoritesProvider` (list of favorited locations) and `isFavoriteProvider` (per location)
- [ ] Implement `FavoritesScreen` — list of saved locations with location cards, pull-to-refresh, empty state ("No saved spots yet")
- [ ] Wire up favorite button on `LocationDetailScreen` and `LocationCard`
- [ ] Animated heart toggle on favorite button
- [ ] Register new DI dependencies

### Verification Criteria
- [ ] Tapping favorite on detail screen toggles the favorite state
- [ ] Favorites tab shows all favorited locations
- [ ] Removing a favorite updates both the list and the detail screen
- [ ] Empty state shows when no favorites
- [ ] Favorite state persists across app restarts
- [ ] Only authenticated user's favorites are shown (RLS)

### Exit Criteria
Users can save/unsave locations, view their favorites list, and favorite state is synced across all screens.

---

## Phase 7: Reviews Feature
**Type**: Full Stack (Data + UI)
**Estimated**: 6-7 hours
**Files**: `lib/features/reviews/data/datasources/reviews_remote_datasource.dart` (new), `lib/features/reviews/data/models/review_model.dart` (new), `lib/features/reviews/data/repositories/reviews_repository_impl.dart` (new), `lib/features/reviews/domain/entities/review.dart` (new), `lib/features/reviews/domain/repositories/reviews_repository.dart` (new), `lib/features/reviews/domain/usecases/` (new, 3-4 files), `lib/features/reviews/presentation/providers/reviews_provider.dart` (new), `lib/features/reviews/presentation/widgets/review_card.dart` (new), `lib/features/reviews/presentation/widgets/review_form.dart` (new), `lib/features/reviews/presentation/widgets/rating_bar.dart` (new)

### Tasks
- [ ] Create `Review` entity (id, locationId, userId, userName, userAvatar, rating, comment, photos, createdAt)
- [ ] Create `ReviewModel` with fromJson/toJson (joins profile data for display name/avatar)
- [ ] Create `ReviewsRemoteDataSource` (getByLocation, create, update, delete)
- [ ] Create `ReviewsRepository` interface and implementation
- [ ] Create use cases: GetLocationReviewsUseCase, CreateReviewUseCase, UpdateReviewUseCase, DeleteReviewUseCase
- [ ] Create `reviewsProvider` (per location), `createReviewProvider`
- [ ] Implement `ReviewCard` widget (avatar, name, rating stars, comment, timeago timestamp, photos)
- [ ] Implement `RatingBar` widget (interactive star selector)
- [ ] Implement `ReviewForm` bottom sheet (star rating, text input, optional photo upload)
- [ ] Add reviews section to `LocationDetailScreen` (show latest 3 + "View All" link)
- [ ] Reviews list screen (all reviews for a location, sorted newest first)
- [ ] Update location's `rating` and `review_count` via Supabase trigger or RPC on review create/delete
- [ ] Register DI dependencies

### Verification Criteria
- [ ] Reviews load on location detail screen
- [ ] User can submit a review with rating + comment
- [ ] Review appears immediately after submission
- [ ] User can edit/delete their own review
- [ ] Location's average rating updates after review submission
- [ ] Review photos display correctly
- [ ] Timeago timestamps display correctly ("2 hours ago", "3 days ago")
- [ ] User cannot review the same location twice (update instead)

### Exit Criteria
Full review system — view reviews on location detail, submit/edit/delete reviews, ratings auto-calculate, photos in reviews.

---

## Phase 8: Check-In Feature
**Type**: Full Stack (Data + UI)
**Estimated**: 4-5 hours
**Files**: `lib/features/checkins/data/datasources/checkin_remote_datasource.dart` (new), `lib/features/checkins/data/models/checkin_model.dart` (new), `lib/features/checkins/data/repositories/checkin_repository_impl.dart` (new), `lib/features/checkins/domain/entities/checkin.dart` (new), `lib/features/checkins/domain/repositories/checkin_repository.dart` (new), `lib/features/checkins/domain/usecases/` (new, 2-3 files), `lib/features/checkins/presentation/providers/checkin_provider.dart` (new), `lib/features/checkins/presentation/widgets/checkin_dialog.dart` (new)

### Tasks
- [ ] Create `CheckIn` entity (id, locationId, userId, note, photoUrl, createdAt)
- [ ] Create `CheckInModel` with fromJson/toJson
- [ ] Create `CheckInRemoteDataSource` (create, getByUser, getByLocation)
- [ ] Create `CheckInRepository` interface and implementation
- [ ] Create use cases: CreateCheckInUseCase, GetUserCheckInsUseCase, GetLocationCheckInsUseCase
- [ ] Create providers: `checkInProvider`, `userCheckInsProvider`
- [ ] Implement check-in dialog (optional note, optional photo from camera/gallery)
- [ ] Wire up check-in button on `LocationDetailScreen`
- [ ] Proximity validation — only allow check-in within ~200m of location (using geolocator)
- [ ] Update location `check_in_count` via Supabase trigger
- [ ] Show check-in count on location cards and detail screen
- [ ] Register DI dependencies

### Verification Criteria
- [ ] Check-in button works on location detail
- [ ] Check-in dialog allows note + optional photo
- [ ] Proximity check prevents remote check-ins (shows error if too far)
- [ ] Check-in count updates on the location
- [ ] User's check-in history is accessible
- [ ] Can't check in to the same location more than once per day

### Exit Criteria
Users can check in to locations when nearby, optionally with a note/photo. Check-in counts are tracked and visible.

---

## Phase 9: Profile Screen
**Type**: UI + Data
**Estimated**: 4-5 hours
**Files**: `lib/features/profile/presentation/screens/profile_screen.dart`, `lib/features/profile/presentation/widget/profile_header.dart`, `lib/features/profile/presentation/widget/stats_widget.dart`, `lib/features/profile/presentation/widget/profile_photo_picker.dart`, `lib/features/profile/presentation/providers/profile_provider.dart`, `lib/features/profile/data/datasources/profile_remote_datasource.dart` (new), `lib/features/profile/data/models/profile_model.dart` (new), `lib/features/profile/data/repositories/profile_repository_impl.dart` (new), `lib/features/profile/domain/entities/profile.dart` (new), `lib/features/profile/domain/repositories/profile_repository.dart` (new)

### Tasks
- [ ] Create `Profile` entity (id, username, fullName, avatarUrl, bio, totalCheckIns, totalReviews, joinedAt)
- [ ] Create `ProfileModel` with fromJson/toJson
- [ ] Create data layer (datasource, repository)
- [ ] Create use cases: GetProfileUseCase, UpdateProfileUseCase
- [ ] Implement `ProfileScreen` with: avatar, name, bio, join date, stats grid
- [ ] Implement `ProfileHeader` — avatar with edit overlay, display name, username
- [ ] Implement `StatsWidget` — total check-ins, total reviews, total favorites count
- [ ] Implement `ProfilePhotoPicker` — pick from gallery, upload to Supabase storage `avatars` bucket
- [ ] Edit profile bottom sheet (name, username, bio)
- [ ] Sign out button
- [ ] Check-in history list (recent check-ins)
- [ ] My reviews list
- [ ] Register DI dependencies

### Verification Criteria
- [ ] Profile loads current user data from Supabase
- [ ] Avatar can be changed (pick image → upload → update profile)
- [ ] Stats show correct counts
- [ ] Edit profile updates Supabase and UI immediately
- [ ] Sign out clears session and returns to sign-in screen
- [ ] Check-in history shows recent check-ins
- [ ] My reviews shows user's reviews

### Exit Criteria
Profile screen displays user information, stats, and allows editing. Sign out works correctly. Check-in history and review history are visible.

---

## Phase 10: Search Screen
**Type**: UI
**Estimated**: 3-4 hours
**Files**: `lib/features/search/presentation/screens/search_screen.dart` (new), `lib/features/search/presentation/widgets/search_results_list.dart` (new), `lib/features/search/presentation/widgets/recent_searches.dart` (new)

### Tasks
- [ ] Implement full-screen search screen with auto-focus text field
- [ ] Debounced search input (300ms delay)
- [ ] Show recent searches (stored in Hive local storage)
- [ ] Show search results using existing `searchResultsProvider`
- [ ] Result items as compact location cards
- [ ] "No results" state with suggestions ("Try searching for cafes, parks, or restaurants")
- [ ] Clear search / clear recent searches
- [ ] Navigate to location detail on result tap
- [ ] Save search query to recent searches on result tap
- [ ] Uncomment and wire up search route in `app_router.dart`

### Verification Criteria
- [ ] Search field auto-focuses on screen open
- [ ] Results appear after typing with debounce
- [ ] Recent searches persist and can be tapped to re-search
- [ ] Results navigate to location detail
- [ ] Empty state and no-results state display correctly

### Exit Criteria
Full-text search works with debounce, recent search history, and navigation to results.

---

## Phase 11: Surprise Me Feature
**Type**: UI
**Estimated**: 3-4 hours
**Files**: `lib/features/discovery/presentation/screens/surprise_screen.dart`, `lib/features/discovery/presentation/widgets/surprise_me_button.dart`, `lib/features/discovery/domain/usecases/get_random_location_usecase.dart`

### Tasks
- [ ] Implement `GetRandomLocationUseCase` (random selection from Supabase, optionally filtered by category and distance)
- [ ] Implement `SurpriseScreen` with animated reveal experience
  - Lottie animation while "deciding"
  - Card reveal with location info
  - "Take Me There" button (opens directions)
  - "Try Again" button (re-randomize)
  - Category preference selector (optional: "Surprise me with..." any / food / coffee / etc.)
- [ ] Implement `SurpriseMeButton` widget for reuse
- [ ] Wire up the FAB center button in `MainShell` to navigate to surprise screen
- [ ] Uncomment surprise route in `app_router.dart`

### Verification Criteria
- [ ] FAB opens surprise screen
- [ ] Random location is selected and displayed with animation
- [ ] "Try Again" picks a different location
- [ ] "Take Me There" opens external maps
- [ ] Category filter works on surprise selection
- [ ] Handles edge case of no locations available

### Exit Criteria
Surprise Me feature provides a fun randomized location discovery experience with animations and directions.

---

## Phase 12: Suggest a Spot Feature
**Type**: Full Stack (Data + UI)
**Estimated**: 3-4 hours
**Files**: `lib/features/suggestions/data/datasources/suggestions_remote_datasource.dart` (new), `lib/features/suggestions/data/models/suggestion_model.dart` (new), `lib/features/suggestions/data/repositories/suggestions_repository_impl.dart` (new), `lib/features/suggestions/domain/entities/suggestion.dart` (new), `lib/features/suggestions/domain/repositories/suggestions_repository.dart` (new), `lib/features/suggestions/domain/usecases/submit_suggestion_usecase.dart` (new), `lib/features/suggestions/presentation/screens/suggest_screen.dart` (new), `lib/features/suggestions/presentation/providers/suggestion_provider.dart` (new)

### Tasks
- [ ] Create `Suggestion` entity (id, userId, name, description, category, address, latitude, longitude, reason, status, createdAt)
- [ ] Create data layer (model, datasource, repository)
- [ ] Create `SubmitSuggestionUseCase`
- [ ] Implement suggest screen form: name, category dropdown, address, description, "why should we add this?" field
- [ ] Optional map pin picker for coordinates
- [ ] Form validation (name required, category required, address required)
- [ ] Success confirmation screen/dialog
- [ ] Show user's past suggestions with statuses (pending, approved, rejected)
- [ ] Uncomment suggest route in `app_router.dart`
- [ ] Register DI dependencies

### Verification Criteria
- [ ] Suggestion form validates inputs
- [ ] Submission creates row in `suggestions` table
- [ ] User can see their past suggestions
- [ ] Suggestion statuses display correctly
- [ ] Form resets after successful submission

### Exit Criteria
Users can suggest new spots via a form. Suggestions are stored in Supabase for admin review.

---

## Phase 13: Router & Navigation Finalization
**Type**: Infrastructure
**Estimated**: 2-3 hours
**Files**: `lib/config/routes/app_router.dart`, `lib/config/shell/main_shell.dart`, `lib/config/shell/shell_provider.dart`

### Tasks
- [ ] Uncomment and wire up all routes in `app_router.dart`: discovery, explore, favorites, profile, location detail, search, suggest, surprise
- [ ] Implement `ShellRoute` for bottom navigation (currently routes are flat, not nested under shell)
- [ ] Ensure tab state is preserved when switching tabs (each tab has its own navigator)
- [ ] Handle deep linking: `/locations/:id` opens detail from any context
- [ ] Ensure back navigation works correctly from full-screen routes (detail, search, suggest, surprise)
- [ ] Fix auth redirect logic for all new routes
- [ ] Remove video onboarding testing reset (currently resets onboarding every launch)

### Verification Criteria
- [ ] All 5 tabs navigate correctly
- [ ] Tab state is preserved (scroll position, filter state)
- [ ] Full-screen routes (detail, search, surprise, suggest) overlay correctly
- [ ] Deep links work
- [ ] Auth guard redirects unauthenticated users
- [ ] Onboarding only shows once (testing reset removed)

### Exit Criteria
Complete navigation system with shell routing, preserved tab state, deep linking, and proper auth guards.

---

## Phase 14: Polish, Performance & QA
**Type**: Testing + UI
**Estimated**: 4-5 hours
**Files**: Various (across all features)

### Tasks
- [ ] Add error handling and retry UI for all network failures
- [ ] Add pull-to-refresh on all list screens
- [ ] Optimize image loading (proper CachedNetworkImage placeholders, error builders)
- [ ] Add Material motion animations (shared element transitions on location card → detail)
- [ ] Responsive layout adjustments for different screen sizes
- [ ] Keyboard handling (dismiss on scroll, proper focus management)
- [ ] Memory/performance profiling (check for widget rebuilds, provider leaks)
- [ ] Accessibility: semantic labels, sufficient contrast, tap target sizes
- [ ] Test complete user flows end-to-end
- [ ] Fix any discovered bugs
- [ ] Remove all TODO comments and debug prints

### Verification Criteria
- [ ] No crashes during normal usage flows
- [ ] Network errors show user-friendly messages with retry options
- [ ] Images load smoothly with placeholders
- [ ] Animations are smooth (60fps)
- [ ] All user flows work end-to-end: onboarding → sign in → browse → filter → view detail → favorite → review → check in → profile → search → surprise

### Exit Criteria
App is polished, performant, and handles edge cases gracefully. All features work together cohesively.

---

## Notes

**Testing Strategy**: Inline per-phase verification. Manual testing against Supabase. Consider adding unit tests for use cases in a future sprint.

**Deployment Strategy**: Test on physical Android device throughout. Deploy via `flutter build apk` milestones at Phase 4 (list + detail), Phase 8 (core features complete), Phase 14 (full app).

**Context Management**: Phases sized to fit in single sessions. Each phase has clear entry/exit points.

**Dependency Chain**:
```
Phase 1 (DB) → Phase 2 (Seed Data) → Phase 3 (Location List) → Phase 4 (Location Detail)
                                                                      ↓
Phase 5 (Map) ←──────────────────────────────────────────────────── Phase 4
Phase 6 (Favorites) ←──── Phase 4
Phase 7 (Reviews) ←────── Phase 4
Phase 8 (Check-ins) ←──── Phase 4 + Phase 5 (needs geolocation)
Phase 9 (Profile) ←────── Phase 7 + Phase 8 (needs review/checkin data)
Phase 10 (Search) ←────── Phase 3 (reuses search provider)
Phase 11 (Surprise) ←──── Phase 5 (reuses map/location data)
Phase 12 (Suggest) ←────── Phase 1 (only needs DB)
Phase 13 (Navigation) ←── All feature phases
Phase 14 (Polish) ←─────── All phases
```
