# Feed Integration Guide

This guide will help you integrate the Instagram-like feed functionality into your existing iOS app.

## Step 1: Update Your SupabaseManager

First, update your existing SupabaseManager or create one if it doesn't exist:

```swift
// In your existing SupabaseManager or create a new one
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Replace with your actual Supabase credentials
        self.client = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )
    }
}
```

## Step 2: Add Feed to Your Navigation

### Option A: Add to Tab Bar

If you have a tab bar, add the feed as a new tab:

```swift
// In your main ContentView or TabView
TabView {
    // Your existing tabs...
    
    FeedView(client: SupabaseManager.shared.client)
        .tabItem {
            Image(systemName: "photo.on.rectangle.angled")
            Text("Feed")
        }
    
    // Other tabs...
}
```

### Option B: Add to Navigation

If you're using navigation, add it to your navigation stack:

```swift
NavigationLink("Feed") {
    FeedView(client: SupabaseManager.shared.client)
}
```

### Option C: Replace Home View

You can replace your existing home view with the feed:

```swift
// In your main app file
ContentView()
    .sheet(isPresented: $showingFeed) {
        FeedView(client: SupabaseManager.shared.client)
    }
```

## Step 3: Update Your Photo Upload Flow

Modify your existing photo upload to also create a post in the feed:

```swift
// In your existing PhotoService or wherever you handle photo uploads
func uploadPhotoAndCreatePost(imageData: Data, title: String?, description: String?) async throws {
    // Your existing photo upload logic...
    let photoURL = try await saveRunwareImage(runwareURL: imageURL, title: title, description: description)
    
    // Now also create a post in the feed
    let feedService = FeedService(client: SupabaseManager.shared.client)
    _ = try await feedService.createPost(
        imageUrl: photoURL,
        title: title,
        description: description,
        isPublic: true
    )
}
```

## Step 4: Update Your App's Main View

Here's how you might integrate the feed into your existing `ContentView.swift`:

```swift
// In your ContentView.swift
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Your existing home view
            Home()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            // New feed view
            FeedView(client: SupabaseManager.shared.client)
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Feed")
                }
                .tag(1)
            
            // Your other existing tabs...
            GalleryView()
                .tabItem {
                    Image(systemName: "photo.stack")
                    Text("Gallery")
                }
                .tag(2)
            
            Settings()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
    }
}
```

## Step 5: Handle Authentication

Make sure your feed respects authentication:

```swift
// In FeedView.swift, add authentication check
struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                feedContent
            } else {
                authenticationPrompt
            }
        }
        .task {
            await checkAuthentication()
        }
    }
    
    private var authenticationPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Sign In Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please sign in to view the feed")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Sign In") {
                // Navigate to your sign-in view
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func checkAuthentication() async {
        // Check if user is authenticated
        isAuthenticated = SupabaseManager.shared.client.auth.currentSession != nil
    }
}
```

## Step 6: Customize the UI

### Update Colors and Styling

```swift
// In your UIThemes.swift or create a new theme file
extension Color {
    static let feedBackground = Color(.systemBackground)
    static let feedCardBackground = Color(.secondarySystemBackground)
    static let feedText = Color(.label)
    static let feedSecondaryText = Color(.secondaryLabel)
}

// Update PostCardView to use your theme
struct PostCardView: View {
    var body: some View {
        VStack {
            // Your post content...
        }
        .background(Color.feedCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
```

### Add Your App's Branding

```swift
// In FeedView.swift
struct FeedView: View {
    var body: some View {
        NavigationView {
            VStack {
                // Custom header with your app's branding
                customHeader
                
                feedContent
            }
        }
    }
    
    private var customHeader: some View {
        HStack {
            Image("YourAppLogo") // Your app's logo
                .resizable()
                .frame(width: 30, height: 30)
            
            Text("Your App Name")
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .background(Color.feedBackground)
    }
}
```

## Step 7: Add Feed to Your Camera/Gallery Flow

### Option A: Add "Share to Feed" Option

```swift
// In your existing photo capture or gallery view
struct PhotoCaptureView: View {
    @State private var showingShareOptions = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        VStack {
            // Your existing camera/gallery UI...
            
            if let image = capturedImage {
                Button("Share to Feed") {
                    showingShareOptions = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showingShareOptions) {
            ShareToFeedView(image: capturedImage!)
        }
    }
}

struct ShareToFeedView: View {
    let image: UIImage
    @State private var description = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
                
                TextField("Add a description...", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Post to Feed") {
                    // Upload image and create post
                    Task {
                        await uploadAndPost()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Share to Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func uploadAndPost() async {
        // Your upload logic here
        dismiss()
    }
}
```

### Option B: Automatic Feed Integration

```swift
// Modify your existing photo upload to automatically add to feed
func uploadPhoto(image: UIImage, description: String?) async {
    do {
        // Your existing upload logic
        let photoURL = try await uploadToStorage(image: image)
        
        // Automatically create a post
        let feedService = FeedService(client: SupabaseManager.shared.client)
        _ = try await feedService.createPost(
            imageUrl: photoURL,
            title: nil, // You can add title parameter here if needed
            description: description,
            isPublic: true
        )
        
        // Show success message
        showSuccessMessage("Photo shared to feed!")
        
    } catch {
        showErrorMessage("Failed to share photo: \(error.localizedDescription)")
    }
}
```

## Step 8: Add Notifications (Optional)

```swift
// Add notification handling for likes and comments
class NotificationManager {
    static let shared = NotificationManager()
    
    func setupNotifications() {
        // Request permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    func scheduleLikeNotification(from user: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Like"
        content.body = "\(user) liked your post"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

## Step 9: Performance Optimization

### Add Caching

```swift
// Add image caching to improve performance
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    func getImage(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    func setImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
}

// Update AsyncImage to use cache
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        // Check cache first
        if let cachedImage = ImageCache.shared.getImage(for: url.absoluteString) {
            image = cachedImage
            return
        }
        
        // Load from network
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                ImageCache.shared.setImage(downloadedImage, for: url.absoluteString)
                image = downloadedImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}
```

## Step 10: Testing

### Test Checklist

- [ ] Feed loads correctly
- [ ] Posts display with images and descriptions
- [ ] Like/unlike functionality works
- [ ] Comments can be added and viewed
- [ ] User profiles can be accessed
- [ ] Photo upload creates posts in feed
- [ ] Authentication works properly
- [ ] Performance is acceptable
- [ ] Error handling works
- [ ] UI matches your app's design

### Debug Tips

1. **Check Console Logs**: Look for any Supabase errors
2. **Test Database**: Verify tables and policies are set up correctly
3. **Check Network**: Ensure images are loading from storage
4. **Test Authentication**: Make sure user sessions are working
5. **Performance**: Monitor memory usage and loading times

## Next Steps

After integration:

1. **Customize the UI** to match your app's design
2. **Add more features** like following users, notifications, etc.
3. **Optimize performance** with better caching and pagination
4. **Add analytics** to track user engagement
5. **Implement moderation** features if needed
6. **Add search functionality** for users and posts
7. **Create admin tools** for content management

The feed functionality is now ready to be integrated into your app! Make sure to test thoroughly and customize the UI to match your app's design language.
