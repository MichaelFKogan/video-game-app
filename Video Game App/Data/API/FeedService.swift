import Supabase
import Foundation

// MARK: - Data Models

struct Post: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let image_url: String
    let description: String?
    let is_public: Bool
    let created_at: Date
    let updated_at: Date
    
    // Joined fields from user profile
    let user_username: String?
    let user_avatar_url: String?
    let user_display_name: String?
    
    // Computed fields
    var like_count: Int?
    var comment_count: Int?
    var is_liked_by_current_user: Bool?
}

struct Like: Codable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let created_at: Date
}

struct Comment: Codable, Identifiable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let content: String
    let created_at: Date
    
    // Joined fields from user profile
    let user_username: String?
    let user_avatar_url: String?
    let user_display_name: String?
}

struct NewPost: Encodable {
    let user_id: UUID
    let image_url: String
    let description: String?
    let is_public: Bool
}

struct NewComment: Encodable {
    let post_id: UUID
    let user_id: UUID
    let content: String
}

// MARK: - Feed Service

class FeedService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // MARK: - Posts
    
    /// Fetches public posts for the feed with user info and engagement metrics
    func fetchPublicFeed(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        let posts: [Post] = try await client.database
            .from("photos")
            .select("""
                *,
                profiles!photos_user_id_fkey(
                    username,
                    avatar_url,
                    display_name
                ),
                likes(count),
                comments(count)
            """)
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return posts
    }
    
    /// Fetches posts by a specific user
    func fetchUserPosts(userId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        let posts: [Post] = try await client.database
            .from("photos")
            .select("""
                *,
                profiles!photos_user_id_fkey(
                    username,
                    avatar_url,
                    display_name
                ),
                likes(count),
                comments(count)
            """)
            .eq("user_id", value: userId)
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return posts
    }
    
    /// Creates a new post
    func createPost(imageUrl: String, description: String?, isPublic: Bool = true) async throws -> Post {
        guard let session = client.auth.currentSession else {
            throw NSError(domain: "FeedService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        let newPost = NewPost(
            user_id: session.user.id,
            image_url: imageUrl,
            description: description,
            is_public: isPublic
        )
        
        let inserted: [Post] = try await client.database
            .from("photos")
            .insert(newPost)
            .select()
            .execute()
            .value
        
        guard let post = inserted.first else {
            throw NSError(domain: "FeedService", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create post"
            ])
        }
        
        return post
    }
    
    /// Deletes a post (only by the owner)
    func deletePost(postId: UUID) async throws {
        guard let session = client.auth.currentSession else {
            throw NSError(domain: "FeedService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        // Delete likes first
        try await client.database
            .from("likes")
            .delete()
            .eq("post_id", value: postId)
            .execute()
        
        // Delete comments first
        try await client.database
            .from("comments")
            .delete()
            .eq("post_id", value: postId)
            .execute()
        
        // Delete the post
        try await client.database
            .from("photos")
            .delete()
            .eq("id", value: postId)
            .eq("user_id", value: session.user.id)
            .execute()
    }
    
    // MARK: - Likes
    
    /// Toggles like on a post
    func toggleLike(postId: UUID) async throws -> Bool {
        guard let session = client.auth.currentSession else {
            throw NSError(domain: "FeedService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        // Check if already liked
        let existingLikes: [Like] = try await client.database
            .from("likes")
            .select()
            .eq("post_id", value: postId)
            .eq("user_id", value: session.user.id)
            .execute()
            .value
        
        if let existingLike = existingLikes.first {
            // Unlike
            try await client.database
                .from("likes")
                .delete()
                .eq("id", value: existingLike.id)
                .execute()
            return false
        } else {
            // Like
            let newLike = Like(
                id: UUID(),
                post_id: postId,
                user_id: session.user.id,
                created_at: Date()
            )
            
            try await client.database
                .from("likes")
                .insert(newLike)
                .execute()
            return true
        }
    }
    
    /// Checks if current user has liked a post
    func isPostLikedByCurrentUser(postId: UUID) async throws -> Bool {
        guard let session = client.auth.currentSession else {
            return false
        }
        
        let likes: [Like] = try await client.database
            .from("likes")
            .select()
            .eq("post_id", value: postId)
            .eq("user_id", value: session.user.id)
            .execute()
            .value
        
        return !likes.isEmpty
    }
    
    // MARK: - Comments
    
    /// Fetches comments for a post
    func fetchComments(postId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [Comment] {
        let comments: [Comment] = try await client.database
            .from("comments")
            .select("""
                *,
                profiles!comments_user_id_fkey(
                    username,
                    avatar_url,
                    display_name
                )
            """)
            .eq("post_id", value: postId)
            .order("created_at", ascending: true)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return comments
    }
    
    /// Adds a comment to a post
    func addComment(postId: UUID, content: String) async throws -> Comment {
        guard let session = client.auth.currentSession else {
            throw NSError(domain: "FeedService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        let newComment = NewComment(
            post_id: postId,
            user_id: session.user.id,
            content: content
        )
        
        let inserted: [Comment] = try await client.database
            .from("comments")
            .insert(newComment)
            .select("""
                *,
                profiles!comments_user_id_fkey(
                    username,
                    avatar_url,
                    display_name
                )
            """)
            .execute()
            .value
        
        guard let comment = inserted.first else {
            throw NSError(domain: "FeedService", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create comment"
            ])
        }
        
        return comment
    }
    
    /// Deletes a comment (only by the author)
    func deleteComment(commentId: UUID) async throws {
        guard let session = client.auth.currentSession else {
            throw NSError(domain: "FeedService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        try await client.database
            .from("comments")
            .delete()
            .eq("id", value: commentId)
            .eq("user_id", value: session.user.id)
            .execute()
    }
    
    // MARK: - User Profiles
    
    /// Fetches user profile by username
    func fetchUserProfile(username: String) async throws -> UserProfile? {
        let profiles: [UserProfile] = try await client.database
            .from("profiles")
            .select()
            .eq("username", value: username)
            .execute()
            .value
        
        return profiles.first
    }
    
    /// Fetches user profile by ID
    func fetchUserProfile(userId: UUID) async throws -> UserProfile? {
        let profiles: [UserProfile] = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        
        return profiles.first
    }
}
