import Supabase
import Foundation

struct Photo: Codable {
    let id: UUID
    let user_id: UUID
    let image_url: String
    let description: String?
    let is_public: Bool
    let created_at: Date
}

struct NewPhoto: Encodable {
    let user_id: UUID
    let image_url: String
    let storage_path: String
    let description: String
    let is_public: Bool
}


class PhotoService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    /// Uploads a Runware-generated image to Supabase storage,
    /// inserts a row in `photos` table, and returns a signed URL for display.
    func saveRunwareImage(runwareURL: URL,
                          description: String? = nil,
                          isPublic: Bool = true) async throws -> URL {
        
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

        // 6. Generate a signed URL to render in SwiftUI
        let signedUrl = try await client.storage
            .from("photos")
            .createSignedURL(path: photo.image_url, expiresIn: 60 * 60) // 1 hour

        return signedUrl
    }
}
