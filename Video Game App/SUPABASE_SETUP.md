# Supabase Storage Setup for Public Images

## Step 1: Configure Storage Bucket as Public

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Storage** in the left sidebar
4. Find your `photos` bucket
5. Click on the bucket settings (gear icon)
6. Set **Public bucket** to **ON**
7. Save the changes

## Step 2: Update Storage Policies (Optional but Recommended)

You may want to add a policy to allow public read access to images:

1. In the Storage section, go to **Policies**
2. Click **New Policy**
3. Choose **Create a policy from scratch**
4. Set the following:
   - **Policy name**: `Public read access`
   - **Target roles**: `public`
   - **Policy definition**: `true`
   - **Operation**: `SELECT`
5. Save the policy

## Step 3: Test the Setup

After making these changes, your images should load reliably without any expiration issues. The public URLs will be in the format:
```
https://your-project.supabase.co/storage/v1/object/public/photos/user-id/image-id.jpg
```

## Benefits of This Approach

- ✅ No more expired URLs
- ✅ No more loading state issues
- ✅ Simpler caching logic
- ✅ Better performance
- ✅ More reliable image loading

## Security Note

Since images are now public, consider implementing user-level privacy controls in your app if needed. Users can make their entire profile private rather than individual images.
