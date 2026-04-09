-- Seed: Bacolod City locations, 5 per category (30 total)
-- Goal: reduce map pin crowding in the Lacson strip by spreading places city-wide.
-- Categories: food, coffee, nature, nightlife, arts, activities

-- Remove previous curated seed rows first so this file can be rerun safely.
DELETE FROM public.locations
WHERE submitted_by IS NULL;

INSERT INTO public.locations (
  name,
  description,
  category,
  latitude,
  longitude,
  address,
  landmark,
  price_range,
  photos,
  tags,
  is_hidden_gem,
  is_verified,
  has_wifi,
  is_pet_friendly,
  has_parking,
  open_time,
  close_time,
  days_open,
  special_hours_note,
  contact_number,
  instagram_handle
)
VALUES
  -- ==========================================
  -- FOOD (5)
  -- ==========================================
  (
    'Aida''s Chicken Inasal',
    'Classic Bacolod inasal stall at Manokan Country with charcoal-grilled chicken and chicken oil rice.',
    'food', 10.67112, 122.94566,
    'Manokan Country, Reclamation Area, Bacolod City, 6100 Negros Occidental',
    'Inside Manokan Country strip',
    'budget',
    '["https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","inasal","must-try","local-favorite"]'::jsonb,
    false, true, false, false, true,
    '10:00', '22:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Busiest from 6 PM to 9 PM.',
    NULL, NULL
  ),
  (
    'Sharyn''s Cansi House',
    'Well-known local spot for kansi, the Bacolod beef shank soup with a sour-savory profile.',
    'food', 10.67336, 122.95955,
    'C-58 Narra Avenue, Capitol Shopping Center, Bacolod City, 6100 Negros Occidental',
    'Near Narra Avenue, Capitol Shopping Center',
    'budget',
    '["https://images.unsplash.com/photo-1547592180-85f173990554?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","kansi","comfort-food","local-specialty"]'::jsonb,
    false, true, false, false, true,
    '09:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Lunch hours can have long queues.',
    NULL, NULL
  ),
  (
    'Chicken House Bacolod',
    'Local grilled chicken and Filipino comfort meals in a casual neighborhood setup.',
    'food', 10.6728514, 122.9578537,
    'Hilado Street, Bacolod City, 6100 Negros Occidental',
    'Along Hilado Street',
    'budget',
    '["https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["lowkey","grill","budget-friendly","quick-bites"]'::jsonb,
    true, true, false, false, false,
    '10:30', '21:30', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Maria Kucina Familia',
    'Family-style Filipino restaurant serving classic local dishes and grilled specialties.',
    'food', 10.6854066, 122.9562488,
    '24th Street, Lacson Tourism Strip, Bacolod City, 6100 Negros Occidental',
    'Near 24th Street, Lacson area',
    'moderate',
    '["https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["new","family-dining","group-friendly","filipino"]'::jsonb,
    false, true, false, false, true,
    '10:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Diotay''s Eatery',
    'No-frills local eatery known for affordable daily Filipino meals.',
    'food', 10.6789960, 122.9519079,
    'Gatuslao Street, Bacolod City, 6100 Negros Occidental',
    'Along Gatuslao Street',
    'budget',
    '["https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","carinderia","local-eats","daily-specials"]'::jsonb,
    false, true, false, false, false,
    '06:00', '20:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Most active during breakfast and lunch.',
    NULL, NULL
  ),

  -- ==========================================
  -- COFFEE (5)
  -- ==========================================
  (
    'Coffee Culture Roastery',
    'Specialty coffee roastery in Alijis with in-house roasted beans and manual brew options.',
    'coffee', 10.6458667, 122.9382448,
    'Alijis Road, Bacolod City, 6100 Negros Occidental',
    'Along Alijis Road',
    'moderate',
    '["https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","specialty-coffee","roastery","wifi"]'::jsonb,
    false, true, true, false, false,
    '09:00', '18:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Best for manual brew and espresso flights.',
    '+63 949 507 5359', 'coffeecultureroastery.ph'
  ),
  (
    'Calea Pastries and Coffee',
    'Iconic Bacolod dessert and coffee destination, known for cakes and all-day cafe traffic.',
    'coffee', 10.6797042, 122.9547458,
    'Lacson Street, Bacolod City, 6100 Negros Occidental',
    'Near 15th Lacson / L''Fisher area',
    'budget',
    '["https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","cakes","dessert","iconic"]'::jsonb,
    false, true, false, false, false,
    '09:00', '22:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Usually full after dinner hours.',
    '(034) 435-8413', NULL
  ),
  (
    'Also Coffee Bacolod',
    'Minimalist specialty coffee spot near the university belt with a calm work-friendly setup.',
    'coffee', 10.6806797, 122.9627948,
    'La Salle Avenue, Bacolod City, 6100 Negros Occidental',
    'Along La Salle Avenue',
    'moderate',
    '["https://images.unsplash.com/photo-1559744784-d776ea02ba07?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["lowkey","espresso","cold-brew","work-friendly"]'::jsonb,
    true, true, true, false, false,
    '08:00', '18:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Tom N Toms Coffee',
    'Large Korean-style cafe with reliable seating and Wi-Fi for long catch-ups and laptop sessions.',
    'coffee', 10.6862548, 122.9569782,
    '26th Street, Lacson Tourism Strip, Bacolod City, 6100 Negros Occidental',
    'Near 26th Street, Lacson',
    'moderate',
    '["https://images.unsplash.com/photo-1572231086568-6984943e6629?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["new","chain-cafe","wifi","all-day"]'::jsonb,
    false, true, true, false, true,
    '08:00', '22:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Quinos Cafe',
    'Pastry-forward coffee stop popular for cream puffs and quick coffee breaks in north Bacolod.',
    'coffee', 10.6896, 122.9612,
    'Robinsons Place area, Mandalagan, Bacolod City, 6100 Negros Occidental',
    'Near Robinsons Place Bacolod',
    'budget',
    '["https://images.unsplash.com/photo-1582010563554-76177e18c6e0?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","pastries","mall-cafe","budget-friendly"]'::jsonb,
    false, true, true, false, true,
    '10:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),

  -- ==========================================
  -- NATURE (5)
  -- ==========================================
  (
    'Capitol Park and Lagoon',
    'Public park and lagoon in the Capitol area, popular for jogging and evening walks.',
    'nature', 10.6760, 122.95213,
    'Capitol Park, Bacolod City, 6100 Negros Occidental',
    'In front of the Provincial Capitol',
    'free',
    '["https://images.unsplash.com/photo-1769886193910-b04682b49253?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","park","jogging","family-friendly"]'::jsonb,
    false, true, false, true, true,
    '05:00', '22:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Bacolod City Seaside and Reclamation Area',
    'Waterfront stretch near the port with open sunset views and breezy evening walks.',
    'nature', 10.6650, 122.9400,
    'Reclamation Area, Bacolod City, 6100 Negros Occidental',
    'Near Bacolod Seaport',
    'free',
    '["https://images.unsplash.com/photo-1591257773743-ea28737e33d9?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","sunset","waterfront","walking"]'::jsonb,
    false, true, false, true, true,
    '00:00', '23:59', '[1,2,3,4,5,6,7]'::jsonb,
    'Best visited near sunset.',
    NULL, NULL
  ),
  (
    'Bacolod Esplanade',
    'Open-air riverside/esplanade walk area used by joggers and casual walkers in the mornings and evenings.',
    'nature', 10.6565292, 122.9668867,
    'Bacolod Esplanade, Bacolod City, 6100 Negros Occidental',
    'Villamonte side',
    'free',
    '["https://images.unsplash.com/photo-1727549153356-2d3735f07ad5?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["lowkey","morning-walk","open-air","free"]'::jsonb,
    true, true, false, true, false,
    '05:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Bacolod City Government Center Grounds',
    'Large civic grounds with open lawns and walkable spaces around the city government complex.',
    'nature', 10.6588478, 122.9665691,
    'Bacolod City Government Center, Bacolod City, 6100 Negros Occidental',
    'New Government Center',
    'free',
    '["https://images.unsplash.com/photo-1739308416394-4aa312a21d37?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["new","green-space","walks","photography"]'::jsonb,
    false, true, false, true, true,
    '05:00', '20:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'San Sebastian Cathedral and Plaza Garden',
    'Historic cathedral grounds with shaded plaza sections in downtown Bacolod.',
    'nature', 10.6703280, 122.9471513,
    'Rizal Street, Bacolod City, 6100 Negros Occidental',
    'San Sebastian Cathedral',
    'free',
    '["https://images.unsplash.com/photo-1575684309750-6c6701372876?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","heritage","plaza","city-center"]'::jsonb,
    false, true, false, true, false,
    '05:00', '19:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),

  -- ==========================================
  -- NIGHTLIFE (5)
  -- ==========================================
  (
    'MO2 Ice',
    'Bacolod nightclub known for DJ nights, dance floor events, and late-closing weekend crowd.',
    'nightlife', 10.68838, 122.95900,
    'MO2 Westown Hotel area, Mandalagan, Bacolod City, 6100 Negros Occidental',
    'Near Robinsons Place Bacolod',
    'moderate',
    '["https://images.unsplash.com/photo-1687511844598-165c1fc387cc?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","nightclub","dj","party"]'::jsonb,
    false, true, false, false, true,
    '21:00', '03:00', '[4,5,6,7]'::jsonb,
    'Peak nights are Friday and Saturday.',
    NULL, 'mo2ice'
  ),
  (
    'Straight Up Bar at Seda Capitol Central',
    'Rooftop hotel bar with city views, cocktails, and a more polished night-out setting.',
    'nightlife', 10.6767426, 122.9528388,
    'Seda Capitol Central, North Capitol Road, Bacolod City, 6100 Negros Occidental',
    'Seda Capitol Central rooftop',
    'expensive',
    '["https://images.unsplash.com/photo-1623630524058-622b7fa9ecd7?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","rooftop","cocktails","city-view"]'::jsonb,
    false, true, true, false, true,
    '17:00', '00:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Smart casual attire is recommended.',
    '+63 34 703 8888', NULL
  ),
  (
    'Portiko Cafe and Lounge',
    'Cafe-by-day and lounge-by-night concept with cocktails and a relaxed evening crowd.',
    'nightlife', 10.6763, 122.9509,
    '23rd Lacson Street, Bacolod City, 6100 Negros Occidental',
    'Near 23rd Lacson Street',
    'moderate',
    '["https://images.unsplash.com/photo-1702725365102-0bcdb9c80599?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["lowkey","lounge","cocktails","date-spot"]'::jsonb,
    true, true, true, false, false,
    '17:00', '01:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    '(034) 707-7056', 'portikobcd'
  ),
  (
    'Bar 21 Restaurant and Live Music',
    'Local fixture with food, drinks, and regular live music nights in the Lacson strip.',
    'nightlife', 10.6829110, 122.9554311,
    '21st Street, Lacson Tourism Strip, Bacolod City, 6100 Negros Occidental',
    'Corner of 21st and Lacson',
    'budget',
    '["https://images.unsplash.com/photo-1718182147550-5d6f9208432d?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["new","live-music","bar","budget-friendly"]'::jsonb,
    false, true, false, false, false,
    '18:00', '02:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Live acts usually start late evening.',
    NULL, NULL
  ),
  (
    'Casino Filipino at L''Fisher Hotel',
    'City-center casino venue with table games and late-night entertainment.',
    'nightlife', 10.6800, 122.9544,
    '14 Lacson Street, Bacolod City, 6100 Negros Occidental',
    'Inside L''Fisher Hotel',
    'moderate',
    '["https://images.unsplash.com/photo-1603410246916-9b2ca82acdd7?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","casino","night-out","entertainment"]'::jsonb,
    false, true, false, false, true,
    '10:00', '04:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Valid ID required for entry.',
    '(034) 433-3731', NULL
  ),

  -- ==========================================
  -- ARTS (5)
  -- ==========================================
  (
    'The Negros Museum',
    'Regional museum with rotating contemporary exhibits and Negrense heritage collections.',
    'arts', 10.6751622, 122.9503269,
    'Gatuslao Street, Bacolod City, 6100 Negros Occidental',
    'Near Capitol complex',
    'budget',
    '["https://images.unsplash.com/photo-1547296017-978c31e1c124?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","museum","heritage","culture"]'::jsonb,
    false, true, false, false, false,
    '08:30', '16:30', '[2,3,4,5,6,7]'::jsonb,
    'Closed on Mondays.',
    NULL, 'negrosmuseum'
  ),
  (
    'The Orange Project',
    'Contemporary gallery space in the Art District featuring local and visiting artists.',
    'arts', 10.6942, 122.9590,
    'Art District, Lopue''s Annex Building, Santa Clara Avenue, Mandalagan, Bacolod City, 6100 Negros Occidental',
    'Inside Art District, Lopue''s Mandalagan complex',
    'free',
    '["https://images.unsplash.com/photo-1725693080167-17b5db7da655?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","gallery","contemporary","local-artists"]'::jsonb,
    false, true, false, false, false,
    '10:00', '19:00', '[2,3,4,5,6,7]'::jsonb,
    'Exhibits rotate regularly.',
    NULL, 'orangeproject_ph'
  ),
  (
    'The Openspace Art District',
    'Creative district with murals, galleries, and independent spaces concentrated in one block.',
    'arts', 10.6942, 122.9591,
    'Art District, Santa Clara Avenue, Mandalagan, Bacolod City, 6100 Negros Occidental',
    'Art District main grounds',
    'free',
    '["https://images.unsplash.com/photo-1600250665773-c5a87c9c83d5?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["new","murals","community","public-art"]'::jsonb,
    false, true, false, true, false,
    '10:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Dizon-Ramos Museum',
    'Ancestral-house museum with curated antiques, religious pieces, and seasonal displays.',
    'arts', 10.6709948, 122.9516773,
    'Burgos Street, Bacolod City, 6100 Negros Occidental',
    'Burgos residential block',
    'free',
    '["https://images.unsplash.com/photo-1532618448574-fa71ec0b6df4?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["lowkey","museum","antiques","heritage-home"]'::jsonb,
    true, true, false, false, false,
    '09:00', '17:00', '[2,3,4,5,6,7]'::jsonb,
    'Recommended to message ahead before visiting.',
    NULL, NULL
  ),
  (
    'Negros Showroom',
    'Curated artisan and craft showroom featuring local products, design, and giftable pieces.',
    'arts', 10.6770, 122.9514,
    'Lacson Street, Bacolod City, 6100 Negros Occidental',
    'Along Lacson commercial strip',
    'free',
    '["https://images.unsplash.com/photo-1606077089119-92075161bb60?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","crafts","local-products","design"]'::jsonb,
    false, true, false, false, false,
    '09:00', '19:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),

  -- ==========================================
  -- ACTIVITIES (5)
  -- ==========================================
  (
    'Manokan Country Food Crawl',
    'Evening food crawl around multiple inasal stalls and local grill houses in one strip.',
    'activities', 10.67112, 122.94566,
    'Manokan Country, Reclamation Area, Bacolod City, 6100 Negros Occidental',
    'Reclamation Area',
    'budget',
    '["https://images.unsplash.com/photo-1772855386828-a18ff9a12584?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["trending","food-crawl","group-activity","local-experience"]'::jsonb,
    false, true, false, false, true,
    '16:00', '23:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Best time is 6 PM onward.',
    NULL, NULL
  ),
  (
    'Panaad Park and Stadium',
    'Large open sports complex for jogging, events, and festival season activities.',
    'activities', 10.6254, 122.9652,
    'Panaad Park and Stadium, Mansilingan, Bacolod City, 6100 Negros Occidental',
    'Panaad complex',
    'free',
    '["https://images.unsplash.com/photo-1765261176106-6076a63ee433?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","sports","jogging","community"]'::jsonb,
    false, true, false, false, true,
    '06:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    'Hosts large city and provincial events.',
    NULL, NULL
  ),
  (
    'SM City Bacolod',
    'Major mall hub with cinema, dining, and family-friendly indoor activities.',
    'activities', 10.6722145, 122.9443594,
    'SM City Bacolod, Bacolod City, 6100 Negros Occidental',
    'Downtown-reclamation side',
    'budget',
    '["https://images.unsplash.com/photo-1567958436049-f2903793328b?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["new","mall","cinema","family-friendly"]'::jsonb,
    false, true, true, false, true,
    '10:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Ayala Malls Capitol Central',
    'Mixed-use mall space with restaurants, events, and walkable activity zones in the city core.',
    'activities', 10.6770221, 122.9495538,
    'Ayala Malls Capitol Central, Gatuslao Street, Bacolod City, 6100 Negros Occidental',
    'Capitol Central district',
    'moderate',
    '["https://images.unsplash.com/photo-1549366970-6b64335a55cb?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["popular","events","shopping","walkable"]'::jsonb,
    false, true, true, false, true,
    '10:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  ),
  (
    'Robinsons Place Bacolod',
    'North Bacolod mall hub for dining, errands, and casual group hangouts.',
    'activities', 10.6909050, 122.9589638,
    'Robinsons Place Bacolod, Lacson Street, Mandalagan, Bacolod City, 6100 Negros Occidental',
    'Mandalagan commercial area',
    'budget',
    '["https://images.unsplash.com/photo-1622054426807-e4a4f62b0f73?w=1200&h=800&fit=crop&q=80"]'::jsonb,
    '["lowkey","mall","hangout","north-bacolod"]'::jsonb,
    true, true, true, false, true,
    '10:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL,
    NULL, NULL
  );

UPDATE public.locations
SET
  is_seeded = true,
  seeded_at = COALESCE(seeded_at, created_at)
WHERE submitted_by IS NULL
  AND (is_seeded = false OR seeded_at IS NULL);
