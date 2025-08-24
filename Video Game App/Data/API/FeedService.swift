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
    var user_username: String?
    var user_avatar_url: String?
    var user_display_name: String?
    
    // Computed fields
    var like_count: Int?
    var comment_count: Int?
    var is_liked_by_current_user: Bool?
    
    // Computed property for full image URL
    var fullImageURL: URL? {
        let baseURL = "https://rpcbybhyxirakxtvlhhn.supabase.co/storage/v1/object/public/photos/"
        return URL(string: baseURL + image_url)
    }
    
    // MARK: - Custom Coding Keys to handle storage_path as image_url
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case image_url
        case storage_path
        case description
        case is_public
        case created_at
        case updated_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        user_id = try container.decode(UUID.self, forKey: .user_id)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        is_public = try container.decode(Bool.self, forKey: .is_public)
        created_at = try container.decode(Date.self, forKey: .created_at)
        updated_at = try container.decodeIfPresent(Date.self, forKey: .updated_at) ?? created_at
        
        // Handle image_url - try image_url first, then storage_path as fallback
        if let image_url = try? container.decode(String.self, forKey: .image_url) {
            self.image_url = image_url
        } else if let storage_path = try? container.decode(String.self, forKey: .storage_path) {
            self.image_url = storage_path
        } else {
            throw DecodingError.dataCorruptedError(forKey: .image_url, in: container, debugDescription: "Neither image_url nor storage_path found")
        }
        
        // Initialize optional fields
        user_username = nil
        user_avatar_url = nil
        user_display_name = nil
        like_count = nil
        comment_count = nil
        is_liked_by_current_user = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(image_url, forKey: .image_url)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(is_public, forKey: .is_public)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(updated_at, forKey: .updated_at)
    }
}

struct Like: Codable {
    let id: UUID
    let post_id: UUID?
    let user_id: UUID?
    let created_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case post_id
        case user_id
        case created_at
    }
    
    // Initializer for creating new Like objects
    init(id: UUID, post_id: UUID, user_id: UUID, created_at: Date) {
        self.id = id
        self.post_id = post_id
        self.user_id = user_id
        self.created_at = created_at
    }
    
    // Decoder initializer for handling optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        post_id = try container.decodeIfPresent(UUID.self, forKey: .post_id)
        user_id = try container.decodeIfPresent(UUID.self, forKey: .user_id)
        created_at = try container.decodeIfPresent(Date.self, forKey: .created_at) ?? Date()
    }
}

struct Comment: Codable, Identifiable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let content: String
    let created_at: Date
    
    // Joined fields from user profile
    var user_username: String?
    var user_avatar_url: String?
    var user_display_name: String?
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
        print("🔄 Fetching public feed with limit: \(limit), offset: \(offset)")
        
        // Try the optimized JOIN query first
        do {
            return try await fetchPublicFeedWithJoins(limit: limit, offset: offset)
        } catch {
            print("⚠️ JOIN query failed, falling back to original method: \(error)")
            return try await fetchPublicFeedFallback(limit: limit, offset: offset)
        }
    }
    
    /// Optimized version using JOINs
    private func fetchPublicFeedWithJoins(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        // Since JOINs are failing, throw an error to force fallback
        throw NSError(domain: "FeedService", code: 500, userInfo: [
            NSLocalizedDescriptionKey: "JOIN queries not supported, using fallback method"
        ])
    }
    
    /// Fallback version using original N+1 approach
    private func fetchPublicFeedFallback(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        // First, get the basic posts
        let response = try await client.database
            .from("photos")
            .select("*")
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        print("📊 Raw response data: \(String(describing: response.data))")
        
        // Decode the response data directly
        let posts: [Post]
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Create a date formatter that handles microseconds
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Fallback to standard ISO8601 format
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date string does not match expected format")
            }
            posts = try decoder.decode([Post].self, from: response.data)
            print("✅ Fetched \(posts.count) posts from database")
        } catch {
            print("❌ JSON Decoding Error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
        
        // Then, enrich each post with user profile data and engagement metrics
        var enrichedPosts: [Post] = []
        
        // Create a task group to process posts in parallel
        await withTaskGroup(of: (Int, Post).self) { group in
            for (index, post) in posts.enumerated() {
                group.addTask {
                    var enrichedPost = post
                    
                    do {
                        // Get user profile data
                        if let profile = try await self.fetchUserProfile(userId: post.user_id) {
                            enrichedPost.user_username = profile.username
                            enrichedPost.user_avatar_url = profile.avatar_url
                            enrichedPost.user_display_name = profile.display_name
//                            print("✅ Enriched post \(post.id) with user: \(profile.username ?? "nil")")
                        } else {
                            print("⚠️ No profile found for user: \(post.user_id)")
                        }
                        
                        // Get like count
                        let likes: [Like] = try await self.client.database
                            .from("likes")
                            .select("id")
                            .eq("post_id", value: post.id)
                            .execute()
                            .value
                        enrichedPost.like_count = likes.count
                        
                        // Get comment count
                        let comments: [Comment] = try await self.client.database
                            .from("comments")
                            .select("id")
                            .eq("post_id", value: post.id)
                            .execute()
                            .value
                        enrichedPost.comment_count = comments.count
                        
                        return (index, enrichedPost)
                    } catch {
                        print("❌ Error enriching post \(post.id): \(error)")
                        // Return the post even if enrichment fails
                        return (index, enrichedPost)
                    }
                }
            }
            
            // Collect results in order
            for await (index, enrichedPost) in group {
                enrichedPosts.append(enrichedPost)
            }
        }
        
        // Sort by original order
        enrichedPosts.sort { post1, post2 in
            if let index1 = posts.firstIndex(where: { $0.id == post1.id }),
               let index2 = posts.firstIndex(where: { $0.id == post2.id }) {
                return index1 < index2
            }
            return false
        }
        
        print("✅ Enriched \(enrichedPosts.count) posts with user data and engagement metrics")
        return enrichedPosts
    }
    
    /// Fetches posts by a specific user
    func fetchUserPosts(userId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        // First, get the basic posts
        let response = try await client.database
            .from("photos")
            .select("*")
            .eq("user_id", value: userId)
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Create a date formatter that handles microseconds
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to standard ISO8601 format
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date string does not match expected format")
        }
        let posts: [Post] = try decoder.decode([Post].self, from: response.data)
        
        // Then, enrich each post with user profile data and engagement metrics
        var enrichedPosts: [Post] = []
        
        for var post in posts {
            // Get user profile data
            if let profile = try await fetchUserProfile(userId: post.user_id) {
                post.user_username = profile.username
                post.user_avatar_url = profile.avatar_url
                post.user_display_name = profile.display_name
            }
            
            // Get like count
            let likes: [Like] = try await client.database
                .from("likes")
                .select("id")
                .eq("post_id", value: post.id)
                .execute()
                .value
            post.like_count = likes.count
            
            // Get comment count
            let comments: [Comment] = try await client.database
                .from("comments")
                .select("id")
                .eq("post_id", value: post.id)
                .execute()
                .value
            post.comment_count = comments.count
            
            enrichedPosts.append(post)
        }
        
        return enrichedPosts
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
        
        do {
            let response = try await client.database
                .from("likes")
                .select("id")
                .eq("post_id", value: postId)
                .eq("user_id", value: session.user.id)
                .execute()
            
            // Try to decode as Like objects first
            if let likes: [Like] = try? JSONDecoder().decode([Like].self, from: response.data) {
                return !likes.isEmpty
            }
            
            // Fallback: check if the JSON array has any elements
            if let jsonArray = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] {
                return !jsonArray.isEmpty
            }
            
            return false
        } catch {
            print("❌ Error checking like status for post \(postId): \(error)")
            return false
        }
    }
    
    /// Gets the total like count for a post
    func getLikeCount(for postId: UUID) async throws -> Int {
        do {
            let response = try await client.database
                .from("likes")
                .select("id")
                .eq("post_id", value: postId)
                .execute()
            
            // Try to decode as Like objects first
            if let likes: [Like] = try? JSONDecoder().decode([Like].self, from: response.data) {
                return likes.count
            }
            
            // Fallback: count the raw JSON array
            if let jsonArray = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] {
                return jsonArray.count
            }
            
            return 0
        } catch {
            print("❌ Error getting like count for post \(postId): \(error)")
            return 0
        }
    }
    
    // MARK: - Comments
    
    /// Fetches comments for a post
    func fetchComments(postId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [Comment] {
        // First, get the basic comments
        let comments: [Comment] = try await client.database
            .from("comments")
            .select("*")
            .eq("post_id", value: postId)
            .order("created_at", ascending: true)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        // Then, enrich each comment with user profile data
        var enrichedComments: [Comment] = []
        
        for var comment in comments {
            // Get user profile data
            if let profile = try await fetchUserProfile(userId: comment.user_id) {
                comment.user_username = profile.username
                comment.user_avatar_url = profile.avatar_url
                comment.user_display_name = profile.display_name
            }
            
            enrichedComments.append(comment)
        }
        
        return enrichedComments
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
            .select("*")
            .execute()
            .value
        
        guard let comment = inserted.first else {
            throw NSError(domain: "FeedService", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create comment"
            ])
        }
        
        // Enrich the comment with user profile data
        var enrichedComment = comment
        if let profile = try await fetchUserProfile(userId: comment.user_id) {
            enrichedComment.user_username = profile.username
            enrichedComment.user_avatar_url = profile.avatar_url
            enrichedComment.user_display_name = profile.display_name
        }
        
        return enrichedComment
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
        let response = try await client.database
            .from("profiles")
            .select()
            .eq("username", value: username)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Create a date formatter that handles microseconds
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to standard ISO8601 format
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date string does not match expected format")
        }
        
        let profiles: [UserProfile] = try decoder.decode([UserProfile].self, from: response.data)
        return profiles.first
    }
    
    /// Fetches user profile by ID
    func fetchUserProfile(userId: UUID) async throws -> UserProfile? {
//        print("🔍 Fetching profile for user ID: \(userId)")
        
        let response = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
        
//        print("📊 Profile response data: \(String(describing: response.data))")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Create a date formatter that handles microseconds
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to standard ISO8601 format
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date string does not match expected format")
        }
        
        do {
            let profiles: [UserProfile] = try decoder.decode([UserProfile].self, from: response.data)
            let profile = profiles.first
//            print("✅ Found profile: \(profile?.username ?? "nil")")
            return profile
        } catch {
            print("❌ Error decoding profile for user \(userId): \(error)")
            
            // Try to decode as raw JSON to see what we're getting
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("🔍 Raw JSON: \(jsonString)")
            }
            
            // Try fallback decoding
            if let jsonArray = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]],
               let firstProfile = jsonArray.first {
                print("🔍 Raw profile data: \(firstProfile)")
                
                // Try to create a UserProfile from the raw data
                if let profile = UserProfile.from(dictionary: firstProfile) {
                    print("✅ Created profile from raw data: \(profile.username ?? "nil")")
                    return profile
                }
            }
            
            return nil
        }
    }
    
    /// Debug function to check database structure
    func debugDatabaseStructure() async {
        print("🔍 Debugging database structure...")
        
        do {
            // Check photos table structure
            let photosResponse = try await client.database
                .from("photos")
                .select("*")
                .limit(1)
                .execute()
            
            print("📊 Photos table sample data: \(String(describing: photosResponse.data))")
            
            // Check profiles table structure
            let profilesResponse = try await client.database
                .from("profiles")
                .select("*")
                .limit(1)
                .execute()
            
            print("📊 Profiles table sample data: \(String(describing: profilesResponse.data))")
            
            // Check if there are any profiles at all
            let allProfilesResponse = try await client.database
                .from("profiles")
                .select("id, username, display_name, avatar_url")
                .execute()
            
            print("📊 All profiles count: \(String(describing: allProfilesResponse.data))")
            
        } catch {
            print("❌ Error checking database structure: \(error)")
        }
    }
}
