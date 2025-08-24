# Feed Troubleshooting Guide

## Error: "Could not find a relationship between 'photos' and 'profiles' in the schema cache"

This error occurs when the foreign key relationships aren't properly established in your Supabase database.

### Quick Fix Steps:

1. **Run the Database Setup Commands**
   Go to your Supabase SQL Editor and run these commands in **exact order**:

```sql
-- Step 1: Ensure profiles table exists
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Add foreign key to photos table
ALTER TABLE public.photos 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Step 3: Create the foreign key constraint
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'photos_user_id_fkey' 
        AND table_schema = 'public' 
        AND table_name = 'photos'
    ) THEN
        ALTER TABLE public.photos 
        ADD CONSTRAINT photos_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 4: Create indexes
CREATE INDEX IF NOT EXISTS photos_user_id_idx ON public.photos(user_id);
CREATE INDEX IF NOT EXISTS photos_is_public_idx ON public.photos(is_public);
CREATE INDEX IF NOT EXISTS photos_created_at_idx ON public.photos(created_at);
```

2. **Verify the Relationship**
   Run this query to check if the foreign key exists:

```sql
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND tc.table_name = 'photos';
```

3. **Test the Query**
   Run this to test if the relationship works:

```sql
SELECT 
    p.*,
    pr.username,
    pr.display_name,
    pr.avatar_url
FROM public.photos p
LEFT JOIN public.profiles pr ON p.user_id = pr.id
WHERE p.is_public = true
LIMIT 5;
```

### Alternative Solution (Temporary Workaround)

If the foreign key setup is complex, I've updated the `FeedService.swift` to use a simpler approach that doesn't rely on complex joins. The service now:

1. Fetches basic posts first
2. Then enriches each post with user profile data separately
3. Gets like and comment counts individually

This approach is more reliable but slightly slower. Once you get the foreign keys working, you can switch back to the optimized version.

### Common Issues and Solutions:

#### Issue 1: "Table 'profiles' doesn't exist"
**Solution**: Run the profiles table creation command first.

#### Issue 2: "Column 'user_id' already exists"
**Solution**: The `ADD COLUMN IF NOT EXISTS` should handle this, but if it fails, check if the column exists:

```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'photos' AND column_name = 'user_id';
```

#### Issue 3: "Foreign key constraint already exists" or "syntax error at or near NOT"
**Solution**: PostgreSQL doesn't support `IF NOT EXISTS` for `ADD CONSTRAINT`. Use this approach instead:

```sql
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'photos_user_id_fkey' 
        AND table_schema = 'public' 
        AND table_name = 'photos'
    ) THEN
        ALTER TABLE public.photos 
        ADD CONSTRAINT photos_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
END $$;
```

#### Issue 4: "Permission denied"
**Solution**: Make sure you're running the commands as a database owner or have the necessary permissions.

#### Issue 5: "policy already exists"
**Solution**: The policies already exist. Use the updated setup guide that includes `DROP POLICY IF EXISTS` statements before creating policies.

#### Issue 6: "trigger already exists"
**Solution**: The triggers already exist. Use the updated setup guide that includes `DROP TRIGGER IF EXISTS` statements before creating triggers.

#### Issue 7: "storage policy already exists"
**Solution**: The storage policies already exist. Use the updated setup guide that includes `DROP POLICY IF EXISTS` statements before creating storage policies.

#### Issue 8: "relation is already member of publication"
**Solution**: The tables are already added to the real-time publication. Use the updated setup guide that includes conditional checks before adding tables to the publication.

### Testing Your Setup:

1. **Check Tables Exist**:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'photos', 'likes', 'comments');
```

2. **Check Foreign Keys**:
```sql
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public';
```

3. **Test Basic Query**:
```sql
SELECT * FROM public.photos WHERE is_public = true LIMIT 1;
```

4. **Test Join Query**:
```sql
SELECT p.id, p.description, pr.username 
FROM public.photos p 
LEFT JOIN public.profiles pr ON p.user_id = pr.id 
WHERE p.is_public = true 
LIMIT 1;
```

### If Still Having Issues:

1. **Clear Supabase Cache**: Sometimes Supabase caches the old schema. Try waiting a few minutes or restart your app.

2. **Check RLS Policies**: Make sure Row Level Security policies are set up correctly.

3. **Verify User Authentication**: Ensure your app is properly authenticated.

4. **Check Console Logs**: Look for any additional error messages in your Xcode console.

### Performance Note:

The updated `FeedService` uses multiple queries instead of complex joins. This is more reliable but may be slower with many posts. Once everything is working, you can optimize by:

1. Setting up proper foreign key relationships
2. Using the original complex join queries
3. Adding database indexes for better performance

### Next Steps:

1. Run the database setup commands
2. Test the basic queries
3. Try the feed in your app
4. If it works, consider optimizing with proper foreign keys
5. If it doesn't work, check the console for more specific error messages
