import Foundation
import SwiftUI
import Supabase

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePosts = true
    
    private let feedService: FeedService
    private var currentOffset = 0
    private let postsPerPage = 20
    
    init(client: SupabaseClient) {
        self.feedService = FeedService(client: client)
    }
    
    // MARK: - Feed Loading
    
    /// Loads the initial feed
    func loadFeed() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Debug database structure
        await feedService.debugDatabaseStructure()
        
        do {
            let newPosts = try await feedService.fetchPublicFeed(limit: postsPerPage, offset: 0)
            
            // Update posts immediately to show content faster
            posts = newPosts
            currentOffset = newPosts.count
            hasMorePosts = newPosts.count == postsPerPage
            
            // Check like status for each post in the background
            Task {
                await updateLikeStatusForPosts()
            }
            
        } catch {
            errorMessage = "Failed to load feed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Loads more posts for pagination
    func loadMorePosts() async {
        guard !isLoading && hasMorePosts else { return }
        
        isLoading = true
        
        do {
            let newPosts = try await feedService.fetchPublicFeed(limit: postsPerPage, offset: currentOffset)
            
            // Update posts immediately to show content faster
            posts.append(contentsOf: newPosts)
            currentOffset += newPosts.count
            hasMorePosts = newPosts.count == postsPerPage
            
            // Check like status for new posts in the background
            Task {
                await updateLikeStatusForPosts()
            }
            
        } catch {
            errorMessage = "Failed to load more posts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Refreshes the feed
    func refreshFeed() async {
        currentOffset = 0
        hasMorePosts = true
        await loadFeed()
    }
    
    // MARK: - Like Management
    
    /// Toggles like on a post
    func toggleLike(for post: Post) async {
        do {
            let isLiked = try await feedService.toggleLike(postId: post.id)
            
            // Update the post in our array
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].is_liked_by_current_user = isLiked
                
                // Get the updated like count from the server
                let updatedLikeCount = try await feedService.getLikeCount(for: post.id)
                posts[index].like_count = updatedLikeCount
            }
        } catch {
            errorMessage = "Failed to update like: \(error.localizedDescription)"
        }
    }
    
    /// Updates like status for all posts
    private func updateLikeStatusForPosts() async {
        // Use TaskGroup to run queries in parallel
        await withTaskGroup(of: (Int, Bool, Int).self) { group in
            for (index, post) in posts.enumerated() {
                group.addTask {
                    do {
                        let isLiked = try await self.feedService.isPostLikedByCurrentUser(postId: post.id)
                        
                        // Also get the total like count for this post
                        let likeCount = try await self.feedService.getLikeCount(for: post.id)
                        
                        return (index, isLiked, likeCount)
                    } catch {
                        print("Failed to check like status for post \(post.id): \(error)")
                        return (index, false, 0)
                    }
                }
            }
            
            for await (index, isLiked, likeCount) in group {
                if index < self.posts.count {
                    self.posts[index].is_liked_by_current_user = isLiked
                    self.posts[index].like_count = likeCount
                }
            }
        }
    }
    
    // MARK: - Post Management
    
    /// Creates a new post
    func createPost(imageUrl: String, description: String?) async -> Bool {
        do {
            let newPost = try await feedService.createPost(imageUrl: imageUrl, description: description)
            
            // Add the new post to the beginning of the feed
            posts.insert(newPost, at: 0)
            
            return true
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Deletes a post
    func deletePost(_ post: Post) async {
        do {
            try await feedService.deletePost(postId: post.id)
            
            // Remove the post from our array
            posts.removeAll { $0.id == post.id }
            
        } catch {
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
        }
    }
    
    // MARK: - User Profile Navigation
    
    /// Gets the username for a post
    func getUsername(for post: Post) -> String {
        return post.user_username ?? "Unknown User"
    }
    
    /// Gets the display name for a post
    func getDisplayName(for post: Post) -> String {
        return post.user_display_name ?? post.user_username ?? "Unknown User"
    }
    
    /// Gets the avatar URL for a post
    func getAvatarURL(for post: Post) -> URL? {
        guard let avatarUrl = post.user_avatar_url else { return nil }
        return URL(string: avatarUrl)
    }
    
    // MARK: - Utility Methods
    
    /// Formats the like count for display
    func formatLikeCount(_ count: Int?) -> String {
        guard let count = count else { return "0" }
        
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    /// Formats the comment count for display
    func formatCommentCount(_ count: Int?) -> String {
        guard let count = count else { return "0" }
        
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    /// Formats the time since post creation
    func formatTimeAgo(for post: Post) -> String {
        let timeInterval = Date().timeIntervalSince(post.created_at)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval < 2592000 {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: post.created_at)
        }
    }
}
