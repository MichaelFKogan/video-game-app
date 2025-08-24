# Database Test Queries

Run these queries in your Supabase SQL Editor to debug the feed issues:

## 1. Check if photos table has data

```sql
-- Check if photos table exists and has data
SELECT COUNT(*) as total_photos FROM public.photos;

-- Check if there are any public photos
SELECT COUNT(*) as public_photos FROM public.photos WHERE is_public = true;

-- Check the structure of photos table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'photos' AND table_schema = 'public'
ORDER BY ordinal_position;
```

## 2. Check if profiles table has data

```sql
-- Check if profiles table has data
SELECT COUNT(*) as total_profiles FROM public.profiles;

-- Check a few sample profiles
SELECT id, username, display_name, created_at 
FROM public.profiles 
LIMIT 5;
```

## 3. Check the relationship between photos and profiles

```sql
-- Check if photos have user_id values
SELECT COUNT(*) as photos_with_user_id 
FROM public.photos 
WHERE user_id IS NOT NULL;

-- Check if photos have valid user_id references
SELECT p.id, p.user_id, pr.username, pr.display_name
FROM public.photos p
LEFT JOIN public.profiles pr ON p.user_id = pr.id
WHERE p.is_public = true
LIMIT 10;
```

## 4. Test the exact query the app is using

```sql
-- Test the basic photos query
SELECT * 
FROM public.photos 
WHERE is_public = true 
ORDER BY created_at DESC 
LIMIT 5;
```

## 5. Check for any data issues

```sql
-- Check for photos without user_id
SELECT * FROM public.photos WHERE user_id IS NULL;

-- Check for profiles without usernames
SELECT * FROM public.profiles WHERE username IS NULL;

-- Check for duplicate usernames
SELECT username, COUNT(*) 
FROM public.profiles 
WHERE username IS NOT NULL 
GROUP BY username 
HAVING COUNT(*) > 1;
```

## 6. Test image URLs

```sql
-- Check what image_url values look like
SELECT id, image_url, user_id 
FROM public.photos 
WHERE is_public = true 
LIMIT 5;
```

## 7. Check RLS policies

```sql
-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('photos', 'profiles', 'likes', 'comments');

-- Check policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('photos', 'profiles', 'likes', 'comments');
```

## 8. Test authentication

```sql
-- Check current user (run this as an authenticated user)
SELECT auth.uid() as current_user_id;

-- Test if current user can see photos
SELECT COUNT(*) as visible_photos 
FROM public.photos 
WHERE is_public = true;
```

## Expected Results:

1. **Photos table**: Should have at least some rows
2. **Public photos**: Should have at least some rows with `is_public = true`
3. **Profiles table**: Should have profiles for users who have photos
4. **User relationships**: Photos should have valid `user_id` values that reference profiles
5. **Image URLs**: Should be relative paths like `user-id/filename.jpg`
6. **RLS policies**: Should be enabled and policies should exist

## Common Issues:

1. **No public photos**: Photos might not be marked as public
2. **Missing user_id**: Photos might not have user_id values
3. **Missing profiles**: Users might not have profile records
4. **RLS blocking**: Policies might be too restrictive
5. **Authentication**: User might not be authenticated

Run these queries and let me know what the results show!
