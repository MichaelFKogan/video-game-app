import Foundation
import SwiftUI
import Supabase

@MainActor
class GalleryViewModel: ObservableObject {
    @Published var galleryImages: [String] = []   // public URLs
    @Published var photos: [Photo] = []           // full photo objects
    @Published var loadingPhotos: [String] = []   // photos currently being processed
    
    private let client: SupabaseClient
    private let cacheKey = "cachedGalleryImages"  // UserDefaults key
    private let cacheKeyPaths = "cachedGalleryPaths"  // Cache the actual image paths
    
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
    private func saveToCache(_ images: [String], paths: [String]) {
        if let encoded = try? JSONEncoder().encode(images) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            print("💾 Saved \(images.count) images to cache")
        }
        if let encodedPaths = try? JSONEncoder().encode(paths) {
            UserDefaults.standard.set(encodedPaths, forKey: cacheKeyPaths)
        }
    }
    
    // MARK: - Load cached paths
    private func loadCachedPaths() -> [String] {
        if let data = UserDefaults.standard.data(forKey: cacheKeyPaths),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            return decoded
        }
        return []
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
            
            // 2. Extract image paths for cache comparison
            let freshPaths = rows.map { $0.image_url }
            let cachedPaths = loadCachedPaths()
            
            // 3. Only regenerate URLs if paths have changed (public URLs don't expire)
            if freshPaths != cachedPaths {
                // Generate public URLs for all images
                var publicURLs: [String] = []
                for row in rows {
                    let publicUrl = try client.storage
                        .from("photos")
                        .getPublicURL(path: row.image_url)
                        .absoluteString
                    publicURLs.append(publicUrl)
                }
                
                // Only update if the URLs are actually different
                if publicURLs != self.galleryImages {
                    self.galleryImages = publicURLs
                    self.photos = rows
                    saveToCache(publicURLs, paths: freshPaths)
                    print("🔄 Updated gallery with \(publicURLs.count) new images")
                } else {
                    print("✅ URLs are the same, no update needed")
                }
            } else {
                // Just update the photos array, keep existing URLs
                self.photos = rows
                print("✅ Cache is up-to-date, no changes")
            }
            
        } catch {
            print("❌ Failed to refresh gallery: \(error)")
        }
    }
    
    // MARK: - Add new photo immediately (after upload)
    func addNewImage(_ url: String) {
        galleryImages.insert(url, at: 0)
        // Note: This method is kept for backward compatibility but refreshFromSupabase() is preferred
        // as it ensures we have the full photo objects and proper caching
    }
    
    // MARK: - Get photo by URL
    func getPhoto(for url: String) -> Photo? {
        // Find the photo object that corresponds to this URL
        // Since we store photos in the same order as URLs, we can use the index
        if let index = galleryImages.firstIndex(of: url), index < photos.count {
            return photos[index]
        }
        return nil
    }
    
    // MARK: - Loading photo management
    func addLoadingPhoto(_ photoId: String) {
        if !loadingPhotos.contains(photoId) {
            loadingPhotos.append(photoId)
        }
    }
    
    func removeLoadingPhoto(_ photoId: String) {
        loadingPhotos.removeAll { $0 == photoId }
    }
    
    func isPhotoLoading(_ photoId: String) -> Bool {
        return loadingPhotos.contains(photoId)
    }
    
    // MARK: - Preload images for better performance
    func preloadImages() {
        for urlString in galleryImages.prefix(10) { // Preload first 10 images
            if let url = URL(string: urlString) {
                // This will trigger the cache to load the image
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            ImageCache.shared.set(image, forKey: urlString)
                        }
                    }
                }.resume()
            }
        }
    }
    
    // MARK: - Clear image cache (useful for debugging or memory management)
    func clearImageCache() {
        ImageCache.shared.removeAll()
        print("🗑️ Image cache cleared")
    }
    
    // MARK: - Delete photo
    func deletePhoto(photoId: UUID) async {
        do {
            let photoService = PhotoService(client: client)
            try await photoService.deletePhoto(photoId: photoId)
            
            // Remove from local arrays
            if let index = photos.firstIndex(where: { $0.id == photoId }) {
                photos.remove(at: index)
                if index < galleryImages.count {
                    galleryImages.remove(at: index)
                }
                
                // Update cache
                let freshPaths = photos.map { $0.image_url }
                saveToCache(galleryImages, paths: freshPaths)
                
                print("✅ Photo deleted successfully from local state")
            }
        } catch {
            print("❌ Failed to delete photo: \(error)")
        }
    }
}
