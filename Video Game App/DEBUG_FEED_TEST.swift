import SwiftUI
import Supabase

// Simple debug test for feed functionality
struct DebugFeedTest: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else if let error = errorMessage {
                    VStack {
                        Text("Error:")
                            .font(.headline)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Button("Retry") {
                            Task {
                                await loadFeed()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if posts.isEmpty {
                    VStack {
                        Text("No posts found")
                            .font(.headline)
                        
                        Button("Load Feed") {
                            Task {
                                await loadFeed()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Debug Database Structure") {
                            Task {
                                let feedService = FeedService(client: SupabaseManager.shared.client)
                                await feedService.debugDatabaseStructure()
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Post ID: \(post.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("User ID: \(post.user_id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Username: \(post.user_username ?? "Unknown")")
                                        .font(.headline)
                                    
                                    Text("Image URL: \(post.image_url)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    if let description = post.description {
                                        Text("Description: \(description)")
                                            .font(.body)
                                    }
                                    
                                    Text("Likes: \(post.like_count ?? 0)")
                                        .font(.caption)
                                    
                                    Text("Comments: \(post.comment_count ?? 0)")
                                        .font(.caption)
                                    
                                    // Test image loading
                                    AsyncImage(url: constructImageURL(post.image_url)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 200)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 200)
                                            .overlay(
                                                Text("Loading...")
                                                    .foregroundColor(.secondary)
                                            )
                                    }
                                    
                                    Divider()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Debug Feed Test")
            .task {
                await loadFeed()
            }
        }
    }
    
    private func loadFeed() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let feedService = FeedService(client: SupabaseManager.shared.client)
            
            // First, debug the database structure
            await feedService.debugDatabaseStructure()
            
            // Then try to load the feed
            posts = try await feedService.fetchPublicFeed(limit: 5, offset: 0)
            print("✅ Debug: Loaded \(posts.count) posts")
        } catch {
            errorMessage = "Failed to load feed: \(error.localizedDescription)"
            print("❌ Debug: Error loading feed: \(error)")
        }
        
        isLoading = false
    }
    
    private func constructImageURL(_ imagePath: String) -> URL? {
        // If it's already a full URL, use it
        if let url = URL(string: imagePath), url.scheme != nil {
            return url
        } else {
            // If it's a relative path, construct the full Supabase storage URL
            let baseURL = "https://rpcbybhyxirakxtvlhhn.supabase.co/storage/v1/object/public/photos/"
            let fullURLString = baseURL + imagePath
            print("🔗 Debug: Constructed image URL: \(fullURLString)")
            return URL(string: fullURLString)
        }
    }
}
