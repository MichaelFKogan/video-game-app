import Foundation

// MARK: - User Profile Model

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let username: String?
    let display_name: String?
    let avatar_url: String?
    let bio: String?
    let created_at: Date
    let updated_at: Date
    
    // Additional fields for compatibility with existing code
    var profilePhotoURL: String? {
        return avatar_url
    }
    
    // Computed properties for display
    var displayName: String {
        return display_name ?? username ?? "Unknown User"
    }
    
    var hasAvatar: Bool {
        return avatar_url != nil && !avatar_url!.isEmpty
    }
    
    // MARK: - Initializers
    
    init(id: UUID, username: String?, display_name: String? = nil, avatar_url: String? = nil, bio: String? = nil, created_at: Date = Date(), updated_at: Date = Date()) {
        self.id = id
        self.username = username
        self.display_name = display_name
        self.avatar_url = avatar_url
        self.bio = bio
        self.created_at = created_at
        self.updated_at = updated_at
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case display_name
        case avatar_url
        case bio
        case created_at
        case updated_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle both UUID and String ID formats
        if let uuidId = try? container.decode(UUID.self, forKey: .id) {
            id = uuidId
        } else if let stringId = try? container.decode(String.self, forKey: .id),
                  let uuidId = UUID(uuidString: stringId) {
            id = uuidId
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid ID format")
        }
        
        username = try container.decodeIfPresent(String.self, forKey: .username)
        display_name = try container.decodeIfPresent(String.self, forKey: .display_name)
        avatar_url = try container.decodeIfPresent(String.self, forKey: .avatar_url)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        
        // Handle date decoding with fallback
        if let createdDate = try? container.decode(Date.self, forKey: .created_at) {
            created_at = createdDate
        } else {
            created_at = Date()
        }
        
        if let updatedDate = try? container.decode(Date.self, forKey: .updated_at) {
            updated_at = updatedDate
        } else {
            updated_at = Date()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a UserProfile from a dictionary (useful for API responses)
    static func from(dictionary: [String: Any]) -> UserProfile? {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString) else {
            return nil
        }
        
        return UserProfile(
            id: id,
            username: dictionary["username"] as? String,
            display_name: dictionary["display_name"] as? String,
            avatar_url: dictionary["avatar_url"] as? String,
            bio: dictionary["bio"] as? String
        )
    }
    
    /// Creates an empty profile for a new user
    static func empty(for userId: UUID) -> UserProfile {
        return UserProfile(
            id: userId,
            username: nil,
            display_name: nil,
            avatar_url: nil,
            bio: nil
        )
    }
}
