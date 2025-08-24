# Supabase Feed Setup Guide

This guide will help you set up the database schema and policies needed for the Instagram-like feed functionality.

## Step 1: Database Schema

Run these SQL commands in your Supabase SQL Editor:

### 1. Create the `profiles` table (if not already exists)

```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles(username);
CREATE INDEX IF NOT EXISTS profiles_display_name_idx ON public.profiles(display_name);
```

### 2. Create the `likes` table

```sql
-- Create likes table
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES public.photos(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS likes_post_id_idx ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS likes_user_id_idx ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS likes_created_at_idx ON public.likes(created_at);
```

### 3. Create the `comments` table

```sql
-- Create comments table
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES public.photos(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS comments_post_id_idx ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS comments_user_id_idx ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS comments_created_at_idx ON public.comments(created_at);
```

### 4. Update the existing `photos` table (if needed)

```sql
-- Add any missing columns to photos table
ALTER TABLE public.photos 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS photos_user_id_idx ON public.photos(user_id);
CREATE INDEX IF NOT EXISTS photos_is_public_idx ON public.photos(is_public);
CREATE INDEX IF NOT EXISTS photos_created_at_idx ON public.photos(created_at);
```

## Step 2: Row Level Security Policies

### Profiles Policies

```sql
-- Allow users to read all public profiles
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
```

### Photos Policies

```sql
-- Allow users to read public photos
CREATE POLICY "Public photos are viewable by everyone" ON public.photos
    FOR SELECT USING (is_public = true);

-- Allow users to read their own photos (including private ones)
CREATE POLICY "Users can view own photos" ON public.photos
    FOR SELECT USING (auth.uid() = user_id);

-- Allow users to insert their own photos
CREATE POLICY "Users can insert own photos" ON public.photos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own photos
CREATE POLICY "Users can update own photos" ON public.photos
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own photos
CREATE POLICY "Users can delete own photos" ON public.photos
    FOR DELETE USING (auth.uid() = user_id);
```

### Likes Policies

```sql
-- Allow users to read all likes
CREATE POLICY "Likes are viewable by everyone" ON public.likes
    FOR SELECT USING (true);

-- Allow users to insert their own likes
CREATE POLICY "Users can insert own likes" ON public.likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own likes
CREATE POLICY "Users can delete own likes" ON public.likes
    FOR DELETE USING (auth.uid() = user_id);
```

### Comments Policies

```sql
-- Allow users to read all comments
CREATE POLICY "Comments are viewable by everyone" ON public.comments
    FOR SELECT USING (true);

-- Allow users to insert their own comments
CREATE POLICY "Users can insert own comments" ON public.comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own comments
CREATE POLICY "Users can update own comments" ON public.comments
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own comments
CREATE POLICY "Users can delete own comments" ON public.comments
    FOR DELETE USING (auth.uid() = user_id);
```

## Step 3: Database Functions

### Function to handle user creation

```sql
-- Function to automatically create a profile when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name', 'User')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a new user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Function to update timestamps

```sql
-- Function to automatically update the updated_at column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at columns
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_photos_updated_at
    BEFORE UPDATE ON public.photos
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
```

## Step 4: Storage Setup

### Update Storage Policies

```sql
-- Allow public read access to photos bucket
CREATE POLICY "Public read access" ON storage.objects
    FOR SELECT USING (bucket_id = 'photos');

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'photos' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to delete their own photos
CREATE POLICY "Users can delete own photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'photos' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
```

## Step 5: Test the Setup

### Test Queries

You can test the setup by running these queries in the SQL Editor:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'photos', 'likes', 'comments');

-- Check if policies are in place
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'photos', 'likes', 'comments');

-- Test inserting a profile (replace with actual user ID)
-- INSERT INTO public.profiles (id, username, display_name) 
-- VALUES ('your-user-id', 'testuser', 'Test User');
```

## Step 6: Environment Variables

Make sure to update your iOS app with the correct Supabase credentials:

1. Go to your Supabase project settings
2. Copy the Project URL and anon/public key
3. Update the `SupabaseManager` class in your iOS app:

```swift
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "YOUR_PROJECT_URL")!,
            supabaseKey: "YOUR_ANON_KEY"
        )
    }
}
```

## Step 7: Enable Real-time (Optional)

If you want real-time updates for likes and comments:

```sql
-- Enable real-time for the tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.likes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.photos;
```

## Troubleshooting

### Common Issues:

1. **Permission Denied**: Make sure RLS policies are correctly set up
2. **Foreign Key Violations**: Ensure all referenced tables exist
3. **Storage Access**: Verify storage bucket permissions
4. **Real-time Not Working**: Check if real-time is enabled for your tables

### Testing Checklist:

- [ ] Users can create profiles
- [ ] Users can upload photos
- [ ] Public photos are visible to all users
- [ ] Users can like/unlike posts
- [ ] Users can comment on posts
- [ ] Users can view other user profiles
- [ ] Users can only modify their own content
- [ ] Images load correctly from storage

## Next Steps

After setting up the database:

1. Update your iOS app's `SupabaseManager` with the correct credentials
2. Test the feed functionality
3. Implement any additional features like following users, notifications, etc.
4. Add error handling and loading states
5. Optimize performance with pagination and caching
