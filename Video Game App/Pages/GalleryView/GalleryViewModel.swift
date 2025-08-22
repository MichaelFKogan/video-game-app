import Foundation
import SwiftUI
import Supabase

@MainActor
class GalleryViewModel: ObservableObject {
    @Published var galleryImages: [String] = []   // signed URLs
    @Published var photos: [Photo] = []           // full photo objects
    
    private let client: SupabaseClient
    private let cacheKey = "cachedGalleryImages"  // UserDefaults key
    
    init(client: SupabaseClient) {
        self.client = client
        loadFromCache()   // load instantly
        Task { await refreshFromSupabase() } // then refresh in background
    }
    
    // MARK: - Load from local cache
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.galleryImages = decoded
            print("✅ Loaded \(decoded.count) cached images")
        }
    }
    
    // MARK: - Save to local cache
    private func saveToCache(_ images: [String]) {
        if let encoded = try? JSONEncoder().encode(images) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            print("💾 Saved \(images.count) images to cache")
        }
    }
    
    // MARK: - Fetch fresh data from Supabase
    func refreshFromSupabase() async {
        do {
            guard let session = client.auth.currentSession else {
                print("❌ No Supabase session")
                return
            }
            let userId = session.user.id
            
            // 1. Fetch rows from `photos` table
            let rows: [Photo] = try await client.database
                .from("photos")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // 2. Create signed URLs for each photo
            var freshURLs: [String] = []
            for row in rows {
                let signed = try await client.storage
                    .from("photos")
                    .createSignedURL(path: row.image_url, expiresIn: 60 * 60)
                freshURLs.append(signed.absoluteString)
            }
            
            // 3. Merge only if different
            if freshURLs != self.galleryImages {
                self.galleryImages = freshURLs
                self.photos = rows  // Store the full photo objects
                saveToCache(freshURLs)
                print("🔄 Updated gallery with \(freshURLs.count) new images")
            } else {
                print("✅ Cache is up-to-date, no changes")
            }
            
        } catch {
            print("❌ Failed to refresh gallery: \(error)")
        }
    }
    
    // MARK: - Add new photo immediately (after upload)
    func addNewImage(_ url: String) {
        galleryImages.insert(url, at: 0)
        saveToCache(galleryImages)
    }
    
    // MARK: - Get photo by URL
    func getPhoto(for url: String) -> Photo? {
        // Find the photo object that corresponds to this URL
        // This is a simple implementation - in a real app you might want to store URL-to-photo mapping
        return photos.first { photo in
            // Since we don't have a direct mapping, we'll return the first photo for now
            // In a real implementation, you'd want to store the signed URL with the photo
            return true
        }
    }
}
