import Supabase
import Foundation

struct Photo: Codable {
    let id: UUID
    let user_id: UUID
    let image_url: String
    let title: String?
    let description: String?
    let is_public: Bool
    let created_at: Date
}

struct NewPhoto: Encodable {
    let user_id: UUID
    let image_url: String
    let storage_path: String
    let title: String
    let description: String
    let is_public: Bool
}


class PhotoService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    /// Uploads a Runware-generated image to Supabase storage,
    /// inserts a row in `photos` table, and returns a public URL for display.
    func saveRunwareImage(runwareURL: URL,
                          title: String? = nil,
                          description: String? = nil,
                          isPublic: Bool = true) async throws -> String {
        
        // 1. Download the image data from Runware
        let (data, _) = try await URLSession.shared.data(from: runwareURL)

        // 2. Get current user id
        guard let session = client.auth.currentSession else {
            throw NSError(domain: "PhotoService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        let userUUID = session.user.id

        print("✅ Current user ID: \(session.user.id)")
        print("🔍 Parsed UUID: \(userUUID)")

        // 3. Build storage path: <uid>/<uuid>.jpg
        let uidString = userUUID.uuidString.lowercased()
        let fileId = UUID().uuidString.lowercased() // optional, for consistency
        let objectKey = "\(uidString)/\(fileId).jpg"

        print("Uploading to bucket 'photos' path:", objectKey)

        // 4. Upload to Supabase storage
        try await client.storage.from("photos").upload(
            path: objectKey,
            file: data,
            options: FileOptions(contentType: "image/jpeg")
        )

        // 5. Insert DB row in `photos` (store objectKey, not path-with-photos/)
        let newPhoto = NewPhoto(
            user_id: userUUID,
            image_url: objectKey,   // ✅ matches actual Storage key
            storage_path: objectKey,
            title: title ?? "",
            description: description ?? "",
            is_public: isPublic
        )

        print("🆔 newPhoto.user_id: \(newPhoto.user_id)")

        let inserted: [Photo] = try await client.database
            .from("photos")
            .insert(newPhoto)
            .select()
            .execute()
            .value

        guard let photo = inserted.first else {
            throw NSError(domain: "PhotoService", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to insert photo row"
            ])
        }

        // 6. Generate a public URL (no expiration, no authentication required)
        let publicUrl = try client.storage
            .from("photos")
            .getPublicURL(path: photo.image_url)
            .absoluteString

        print("✅ Generated public URL: \(publicUrl)")
        return publicUrl
    }
    
    /// Deletes a photo from both Supabase storage and database
    func deletePhoto(photoId: UUID) async throws {
        // 1. Get current user id for verification
        guard let session = client.auth.currentSession else {
            throw NSError(domain: "PhotoService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        let userUUID = session.user.id
        
        // 2. First, get the photo details to get the storage path
        let photos: [Photo] = try await client.database
            .from("photos")
            .select()
            .eq("id", value: photoId)
            .eq("user_id", value: userUUID) // Ensure user owns the photo
            .execute()
            .value
        
        guard let photo = photos.first else {
            throw NSError(domain: "PhotoService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Photo not found or you don't have permission to delete it"
            ])
        }
        
        // 3. Delete from Supabase storage
        try await client.storage
            .from("photos")
            .remove(paths: [photo.image_url])
        
        // 4. Delete from database
        try await client.database
            .from("photos")
            .delete()
            .eq("id", value: photoId)
            .eq("user_id", value: userUUID) // Double-check user ownership
            .execute()
        
        print("✅ Successfully deleted photo with ID: \(photoId)")
    }
}
