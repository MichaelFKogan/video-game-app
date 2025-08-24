ALTER TABLE public.photos
ADD COLUMN IF NOT EXISTS title text,
ADD COLUMN IF NOT EXISTS description text;
