-- Seed: Sample Bacolod locations for development
-- Run via: supabase db reset (applies migrations then seeds)

INSERT INTO public.locations (name, description, category, latitude, longitude, address, landmark, price_range, photos, tags, is_hidden_gem, is_verified, has_wifi, is_pet_friendly, has_parking, open_time, close_time, days_open, special_hours_note, contact_number, instagram_handle)
VALUES
  -- ═══ FOOD ═══
  (
    'Calea Pastries and Coffee',
    'Famous for their cakes, pastries, and desserts. A must-visit in Bacolod with a wide selection of sweet treats that locals and tourists love.',
    'food', 10.6804, 122.9547,
    'Lacson Street, Bacolod City', 'Near Capitol Lagoon',
    'moderate',
    '["https://placehold.co/600x400?text=Calea"]'::jsonb,
    '["dessert","cakes","pastries","date-spot"]'::jsonb,
    false, true, true, false, true,
    '10:00', '22:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, '@caleabacolod'
  ),
  (
    'Merzci Pasalubong',
    'Iconic Bacolod pasalubong shop known for piaya, napoleones, and other Negrense delicacies. Multiple branches across the city.',
    'food', 10.6785, 122.9510,
    'Lacson Street, Bacolod City', NULL,
    'budget',
    '["https://placehold.co/600x400?text=Merzci"]'::jsonb,
    '["pasalubong","piaya","napoleones","local-favorites"]'::jsonb,
    false, true, false, false, true,
    '07:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, '@merzci'
  ),
  (
    '21 Restaurant',
    'A beloved Bacolod institution serving comforting Filipino dishes. Known for their chicken inasal and homestyle cooking in a casual setting.',
    'food', 10.6822, 122.9568,
    'Lacson Street, Bacolod City', 'Near SM City Bacolod',
    'budget',
    '["https://placehold.co/600x400?text=21Restaurant"]'::jsonb,
    '["filipino","chicken-inasal","local-favorites","casual-dining"]'::jsonb,
    false, true, false, false, true,
    '06:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, NULL
  ),
  (
    'Bongbongs Pasalubong',
    'Another top pasalubong destination in Bacolod famous for piaya, barquillos, and other local treats. Family-owned and a staple of Negrense food culture.',
    'food', 10.6760, 122.9480,
    'B.S. Aquino Drive, Bacolod City', NULL,
    'budget',
    '["https://placehold.co/600x400?text=Bongbongs"]'::jsonb,
    '["pasalubong","piaya","barquillos","local-favorites"]'::jsonb,
    false, true, false, false, true,
    '07:00', '20:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, NULL
  ),
  (
    'Netongs',
    'A hidden local eatery tucked in a neighborhood. Famous among insiders for their no-frills but incredibly flavorful chicken inasal at unbeatable prices.',
    'food', 10.6900, 122.9650,
    'Mandalagan, Bacolod City', NULL,
    'budget',
    '["https://placehold.co/600x400?text=Netongs"]'::jsonb,
    '["chicken-inasal","hidden-gem","local-favorites","street-food"]'::jsonb,
    true, false, false, false, false,
    '10:00', '20:00', '[1,2,3,4,5,6]'::jsonb,
    'Closed Sundays', NULL, NULL
  ),

  -- ═══ COFFEE ═══
  (
    'Quan Cafe + Bistro',
    'Trendy cafe with great ambiance, specialty coffee, and an all-day brunch menu. Popular among remote workers and friend groups.',
    'coffee', 10.6790, 122.9560,
    'Lacson Street, Bacolod City', NULL,
    'moderate',
    '["https://placehold.co/600x400?text=QuanCafe"]'::jsonb,
    '["specialty-coffee","brunch","wifi","work-friendly"]'::jsonb,
    false, true, true, false, true,
    '08:00', '22:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, '@quancafebistro'
  ),
  (
    'The Coffee Library',
    'Cozy neighborhood coffee shop hidden in a residential area. Locally roasted beans, quiet atmosphere, and the owners passion for coffee shows in every cup.',
    'coffee', 10.6850, 122.9480,
    'Hilado Street, Bacolod City', NULL,
    'budget',
    '["https://placehold.co/600x400?text=CoffeeLibrary"]'::jsonb,
    '["specialty-coffee","cozy","hidden-gem","quiet"]'::jsonb,
    true, false, true, false, false,
    '09:00', '20:00', '[1,2,3,4,5,6]'::jsonb,
    'Closed Sundays', NULL, NULL
  ),
  (
    'Bo''s Coffee',
    'Homegrown Filipino coffee chain with a branch in Bacolod. Consistent quality, comfortable seating, and a solid selection of local and international brews.',
    'coffee', 10.6775, 122.9515,
    'Robinsons Place Bacolod, Bacolod City', 'Inside Robinsons Mall',
    'moderate',
    '["https://placehold.co/600x400?text=BosCoffee"]'::jsonb,
    '["chain-cafe","wifi","work-friendly","mall"]'::jsonb,
    false, true, true, false, true,
    '10:00', '21:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, '@baborncoffee'
  ),

  -- ═══ NATURE ═══
  (
    'The Ruins',
    'A majestic mansion ruin from the early 1900s surrounded by lush gardens. One of Bacolods most iconic landmarks — stunning at sunset when the walls glow golden.',
    'nature', 10.7120, 122.9375,
    'Talisay City, Negros Occidental', 'Talisay, 15 min from Bacolod center',
    'budget',
    '["https://placehold.co/600x400?text=TheRuins"]'::jsonb,
    '["landmark","history","sunset","photography","gardens"]'::jsonb,
    false, true, false, false, true,
    '08:00', '20:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, '@theruinstalisay'
  ),
  (
    'Capitol Park and Lagoon',
    'The heart of Bacolod — a public park with a lagoon, walking paths, and green space. Perfect for morning jogs, afternoon walks, or just sitting on a bench watching the world go by.',
    'nature', 10.6815, 122.9530,
    'South Capitol Road, Bacolod City', 'In front of Provincial Capitol',
    'free',
    '["https://placehold.co/600x400?text=CapitolPark"]'::jsonb,
    '["park","free","walking","family-friendly","morning-jog"]'::jsonb,
    false, true, false, true, true,
    '05:00', '22:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, NULL
  ),
  (
    'Mambukal Mountain Resort',
    'A hot spring resort nestled in the mountains of Murcia. Features seven waterfalls you can trek to, sulfur dip pools, and butterfly gardens. A spontaneous day trip from Bacolod.',
    'nature', 10.5500, 122.8900,
    'Murcia, Negros Occidental', '30 min drive from Bacolod',
    'budget',
    '["https://placehold.co/600x400?text=Mambukal"]'::jsonb,
    '["waterfalls","hot-springs","trekking","day-trip","nature"]'::jsonb,
    false, true, false, false, true,
    '07:00', '17:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, NULL
  ),

  -- ═══ NIGHTLIFE ═══
  (
    'MO2 Restobar',
    'Bacolods most popular nightlife venue. Live bands, DJ nights, great cocktails, and a vibrant crowd. Multiple floors with different vibes.',
    'nightlife', 10.6830, 122.9550,
    'Lacson Street, Bacolod City', NULL,
    'moderate',
    '["https://placehold.co/600x400?text=MO2"]'::jsonb,
    '["live-music","bar","nightlife","dancing","cocktails"]'::jsonb,
    false, true, false, false, true,
    '18:00', '02:00', '[3,4,5,6,7]'::jsonb,
    'Wed-Sun only. Live bands on weekends.', NULL, '@mo2restobar'
  ),
  (
    'Brewery Gastropub',
    'Craft beer bar with a curated selection and bar food. More relaxed vibe than the big clubs — good for groups who want to talk over drinks.',
    'nightlife', 10.6810, 122.9565,
    'Lacson Street, Bacolod City', NULL,
    'moderate',
    '["https://placehold.co/600x400?text=BreweryGastropub"]'::jsonb,
    '["craft-beer","bar","gastropub","chill-vibe"]'::jsonb,
    false, true, true, false, true,
    '17:00', '01:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, NULL
  ),

  -- ═══ ARTS ═══
  (
    'Negros Museum',
    'A cultural museum housed in a beautiful heritage building. Showcases Negrense history, sugar industry heritage, and rotating art exhibitions.',
    'arts', 10.6810, 122.9535,
    'South Capitol Road, Bacolod City', 'Near Capitol Lagoon',
    'budget',
    '["https://placehold.co/600x400?text=NegrosMuseum"]'::jsonb,
    '["museum","history","art","culture","heritage"]'::jsonb,
    false, true, false, false, true,
    '09:00', '17:00', '[2,3,4,5,6]'::jsonb,
    'Closed Sundays and Mondays', NULL, '@negrosmuseum'
  ),
  (
    'Orange Project',
    'An artist-run community art space in a converted warehouse. Hosts exhibitions, workshops, film screenings, and live performances. The beating heart of Bacolods creative scene.',
    'arts', 10.6880, 122.9610,
    'Rizal Street, Bacolod City', NULL,
    'free',
    '["https://placehold.co/600x400?text=OrangeProject"]'::jsonb,
    '["art-gallery","community","workshops","hidden-gem","creative"]'::jsonb,
    true, false, true, false, false,
    '13:00', '20:00', '[2,3,4,5,6]'::jsonb,
    'Event-based schedule. Check Instagram for events.', NULL, '@orangeproject'
  ),

  -- ═══ ACTIVITIES ═══
  (
    'Bacolod Real Coffee',
    'A specialty coffee shop that also runs cupping workshops and barista training. Go for the coffee, stay to learn how to brew like a pro.',
    'activities', 10.6795, 122.9505,
    'Araneta Street, Bacolod City', NULL,
    'moderate',
    '["https://placehold.co/600x400?text=BacolodRealCoffee"]'::jsonb,
    '["workshop","coffee","learning","specialty"]'::jsonb,
    true, false, true, false, true,
    '08:00', '20:00', '[1,2,3,4,5,6]'::jsonb,
    'Workshop schedule varies. DM to book.', NULL, '@bacolodrc'
  ),
  (
    'Campuestohan Highland Resort',
    'Mountain resort with extreme activities — giant swing over a cliff edge, zipline, rock climbing, and horseback riding. Breathtaking views of Bacolod and the sea below.',
    'activities', 10.7250, 122.8800,
    'Talisay City, Negros Occidental', '45 min drive from Bacolod center',
    'moderate',
    '["https://placehold.co/600x400?text=Campuestohan"]'::jsonb,
    '["adventure","zipline","swing","mountain","views","day-trip"]'::jsonb,
    false, true, false, false, true,
    '07:00', '17:00', '[1,2,3,4,5,6,7]'::jsonb,
    NULL, NULL, '@campuestohan'
  );
