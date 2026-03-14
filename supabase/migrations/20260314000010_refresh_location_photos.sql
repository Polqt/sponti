-- Migration: refresh seeded location photos with real image URLs.
-- The seed file now contains real photos, but existing remote rows still keep
-- the old placeholder URLs until they are updated in-place.

WITH seeded_photos(category, address, landmark, photos) AS (
  VALUES
    ('coffee', 'Balay Quince, 15th Lacson Street, Bacolod City, 6100 Negros Occidental', 'In front of L''Fisher Hotel', '["https://images.unsplash.com/photo-1522992519904-2bf3b4faa050?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', 'Alijis Road, Brgy. Alijis, Bacolod City, 6100 Negros Occidental', 'Beside 7-Eleven Alijis', '["https://images.unsplash.com/photo-1559056199-641a0ac8b3f7?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', '19th Lacson Street, Capitol Subdivision, Bacolod City, 6100 Negros Occidental', 'A few meters off Lacson, 19th Street side', '["https://images.unsplash.com/photo-1599599810694-06fa9cfb5a4a?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', '21 Lacson Street, Bacolod City, 6100 Negros Occidental', 'Along Lacson Street near 21st', '["https://images.unsplash.com/photo-1450521DD7352-42145C0FC43B?w=1200&h=800&fit=crop&q=80", "https://images.unsplash.com/photo-1511920170033-f8396924c348?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', 'DOLL Building, 6th Street, Bacolod City, 6100 Negros Occidental', 'Near Capitol Lagoon, along 6th Street', '["https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', '23rd Lacson Street, Bacolod City, 6100 Negros Occidental', 'Along Lacson Street, 23rd Street intersection', '["https://images.unsplash.com/photo-1625059349118-6361089599c7?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', '19th Lacson Street, Bacolod City, 6100 Negros Occidental', 'Along 19th-Lacson St intersection', '["https://images.unsplash.com/photo-1667731616297-9dcece51c54d?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', 'Lacson Street, Bacolod City, 6100 Negros Occidental', 'Along Lacson Street, near Capitol Sub area', '["https://images.unsplash.com/photo-1572231086568-6984943e6629?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', 'Robinsons Central City Walk, Mandalagan, Bacolod City, 6100 Negros Occidental', 'Inside Robinsons Place Mandalagan', '["https://images.unsplash.com/photo-1582010563554-76177e18c6e0?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('coffee', 'Lacson Street, Bacolod City, 6100 Negros Occidental', 'Central Bacolod City area', '["https://images.unsplash.com/photo-1559744784-d776ea02ba07?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'South Capitol Road, Bacolod City, 6100 Negros Occidental', 'In front of the Negros Occidental Provincial Capitol Building', '["https://images.unsplash.com/photo-1769886193910-b04682b49253?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'Brgy. Bata, Bacolod City, 6100 Negros Occidental', 'Panaad Park near the provincial stadium', '["https://images.unsplash.com/photo-1565431318793-499b6f8b0644?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'Reclamation Area, Brgy. Singcang, Bacolod City, 6100 Negros Occidental', 'Near Manokan Country and the Bacolod Seaport', '["https://images.unsplash.com/photo-1591257773743-ea28737e33d9?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'Rizal Street, Bacolod City, 6100 Negros Occidental', 'Adjacent to Bacolod City Plaza', '["https://images.unsplash.com/photo-1575684309750-6c6701372876?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'Rizal Street, Bacolod City, 6100 Negros Occidental', 'City Center, beside San Sebastian Cathedral', '["https://images.unsplash.com/photo-1671240430657-3462d32baa5b?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'South Capitol Road, Bacolod City, 6100 Negros Occidental', 'Provincial Capitol Complex', '["https://images.unsplash.com/photo-1608712729468-fbcf6f1a6065?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'Government Center, Bacolod City, 6100 Negros Occidental', 'Near the New Government Center complex', '["https://images.unsplash.com/photo-1739308416394-4aa312a21d37?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'North Reclamation Area, Bacolod City, 6100 Negros Occidental', 'Near North Bacolod waterfront', '["https://images.unsplash.com/photo-1727549153356-2d3735f07ad5?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'Libertad Street, Bacolod City, 6100 Negros Occidental', 'Behind Libertad Public Market', '["https://images.unsplash.com/photo-1739852836949-64c21cf1484b?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nature', 'Vista Alegre, Bacolod City, 6100 Negros Occidental', 'Eastern outskirts of Bacolod, Brgy. Vista Alegre', '["https://images.unsplash.com/photo-1605757707542-86be546339ae?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', 'MO2 Westown Hotel, Mandalagan, Bacolod City, 6100 Negros Occidental', 'Beside MO2 Westown Hotel', '["https://images.unsplash.com/photo-1687511844598-165c1fc387cc?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', '23rd Lacson Street, Bacolod City, 6100 Negros Occidental', 'Along Lacson Street, 23rd Street intersection', '["https://images.unsplash.com/photo-1702725365102-0bcdb9c80599?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', 'Seda Capitol Central, Lacson Street cor. North Capitol Road, Bacolod City, 6100', 'Rooftop of Seda Capitol Central Hotel', '["https://images.unsplash.com/photo-1623630524058-622b7fa9ecd7?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', 'Stonehill Suites, Corner 18th Street & San Agustin Drive, Bacolod City, 6100', 'Rooftop of Stonehill Suites', '["https://images.unsplash.com/photo-1566830042652-02be23c8be41?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', 'Door 2, Hilado Building, 19th Lacson Street, Bacolod City, 6100', 'Inside Hilado Building, 19th Lacson intersection', '["https://images.unsplash.com/photo-1545227704-a7216c3685d2?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', '6th Street, Bacolod City, 6100 Negros Occidental', 'Along 6th Street near Capitol area', '["https://images.unsplash.com/photo-1555717268-dd1d13661d91?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', '14 Lacson Street, Bacolod City, 6100 Negros Occidental', 'Inside L''Fisher Hotel', '["https://images.unsplash.com/photo-1603410246916-9b2ca82acdd7?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', 'The Palms, 18th Lacson Street, Bacolod City, 6100 Negros Occidental', 'Inside The Palms complex, 18th Lacson', '["https://images.unsplash.com/photo-1723202594786-69445b7164b8?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', '21st Corner Lacson Street, Bacolod City, 6100 Negros Occidental', 'Corner of 21st and Lacson Streets', '["https://images.unsplash.com/photo-1718182147550-5d6f9208432d?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('nightlife', 'Lacson Street, Bacolod City, 6100 Negros Occidental', 'Lacson Street, Mandalagan area', '["https://images.unsplash.com/photo-1564947774160-532ef016eaa6?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Gatuslao Street, Bacolod City, 6100 Negros Occidental', 'Near Hall of Justice and Provincial Capitol', '["https://images.unsplash.com/photo-1547296017-978c31e1c124?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Corner Lacson Street & Santa Clara Avenue, Brgy. Mandalagan, Bacolod City, 6100', 'Inside the Art District complex, Mandalagan', '["https://images.unsplash.com/photo-1725693080167-17b5db7da655?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Corner Lacson Street & Santa Clara Avenue, Brgy. Mandalagan, Bacolod City, 6100', 'Main entrance on Santa Clara Avenue', '["https://images.unsplash.com/photo-1600250665773-c5a87c9c83d5?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Art District, Brgy. Mandalagan, Bacolod City, 6100 Negros Occidental', 'Inside the Art District, Mandalagan', '["https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Mandalagan, Bacolod City, 6100 Negros Occidental', 'Mandalagan area, near the Art District', '["https://images.unsplash.com/photo-1633419946251-6d8b5dd33170?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Bacolod City, 6100 Negros Occidental', 'Residential area, Bacolod City', '["https://images.unsplash.com/photo-1532618448574-fa71ec0b6df4?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Gatuslao Street (West Annex), Bacolod City, 6100 Negros Occidental', 'West Annex of the Negros Museum, Gatuslao Street', '["https://images.unsplash.com/photo-1580580795861-46d20d423984?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Rizal Street, Bacolod City, 6100 Negros Occidental', 'Starts at the City Plaza', '["https://images.unsplash.com/photo-1560804508-4cab0894630b?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Santa Clara Avenue, Brgy. Mandalagan, Bacolod City, 6100', 'Exterior walls of the Art District', '["https://images.unsplash.com/photo-1624982217239-59d768f45922?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('arts', 'Lacson Street, Bacolod City, 6100 Negros Occidental', 'Along Lacson Street', '["https://images.unsplash.com/photo-1606077089119-92075161bb60?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Reclamation Area, Brgy. Singcang, Bacolod City, 6100 Negros Occidental', 'Reclamation Area, near the Bacolod Seaport', '["https://images.unsplash.com/photo-1772855386828-a18ff9a12584?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', '599 Bongbong Villan Building, Corner Pauline Street, Alijis Road, Bacolod City, 6100', 'Alijis area, near Alijis Road', '["https://images.unsplash.com/photo-1563002576-2e4286e7a2a7?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Panaad Park, Brgy. Bata, Bacolod City, 6100 Negros Occidental', 'Panaad Park and Stadium', '["https://images.unsplash.com/photo-1765261176106-6076a63ee433?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Alijis Road, Brgy. Alijis, Bacolod City, 6100 Negros Occidental', 'Coffee Culture Roastery, beside 7-Eleven Alijis', '["https://images.unsplash.com/photo-1625980324627-45235eb4345e?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Lacson Street, Bacolod City, 6100 Negros Occidental', 'Along Lacson Street', '["https://images.unsplash.com/photo-1760598742492-7ad941e658e5?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'SM City Bacolod, Rizal Street, Bacolod City, 6100 Negros Occidental', 'Along Rizal Street, Bacolod City center', '["https://images.unsplash.com/photo-1567958436049-f2903793328b?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Capitol Park and Lagoon, South Capitol Road, Bacolod City, 6100', 'In front of the Provincial Capitol Building', '["https://images.unsplash.com/photo-1620436724526-1dda64b6bca2?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Goldenfield Commercial Complex, Brgy. Singcang, Bacolod City, 6100', 'Goldenfield Complex, Singcang', '["https://images.unsplash.com/photo-1549366970-6b64335a55cb?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Bacolod Ferry Terminal, Reclamation Area, Bacolod City, 6100', 'Bacolod Ferry Terminal (FastCraft Pier)', '["https://images.unsplash.com/photo-1622054426807-e4a4f62b0f73?w=1200&h=800&fit=crop&q=80"]'::jsonb),
    ('activities', 'Libertad Terminal, Bacolod City, 6100 Negros Occidental', 'Libertad Market Terminal (main jeepney hub)', '["https://images.unsplash.com/photo-1532669056749-3feb6ac9bae7?w=1200&h=800&fit=crop&q=80"]'::jsonb)
)
UPDATE public.locations AS locations
SET
  photos = seeded_photos.photos,
  updated_at = now()
FROM seeded_photos
WHERE locations.category = seeded_photos.category
  AND locations.address = seeded_photos.address
  AND COALESCE(locations.landmark, '') = COALESCE(seeded_photos.landmark, '')
  AND locations.photos IS DISTINCT FROM seeded_photos.photos;
