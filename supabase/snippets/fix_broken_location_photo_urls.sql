UPDATE public.locations
SET photos = '["https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&h=800&fit=crop&q=80"]'::jsonb
WHERE name = 'Chicken House Bacolod';

UPDATE public.locations
SET photos = '["https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=1200&h=800&fit=crop&q=80"]'::jsonb
WHERE name = 'Coffee Culture Roastery';

UPDATE public.locations
SET photos = '["https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=1200&h=800&fit=crop&q=80"]'::jsonb
WHERE name = 'Calea Pastries and Coffee';

SELECT name, photos->>0 AS photo
FROM public.locations
WHERE name IN ('Chicken House Bacolod', 'Coffee Culture Roastery', 'Calea Pastries and Coffee')
ORDER BY name;
