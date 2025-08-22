import SwiftUI
import Combine

enum NotificationType {
    case transforming
    case success
    case error
}

struct GlobalNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let message: String
    let timestamp = Date()
    let photoId: String? // Track which photo this notification is for
}

@MainActor
class GlobalNotificationManager: ObservableObject {
    @Published var currentNotification: GlobalNotification?
    @Published var isShowing = false
    
    // Track multiple transformations
    private var transformingPhotos: Set<String> = []
    private var notificationTimer: Timer?
    
    var transformingPhotosCount: Int {
        return transformingPhotos.count
    }
    
    func showTransformingNotification(for photoId: String) {
        transformingPhotos.insert(photoId)
        updateTransformingNotification()
    }
    
    func showSuccessNotification(for photoId: String) {
        transformingPhotos.remove(photoId)
        
        let notification = GlobalNotification(
            type: .success,
            message: "Photo successfully uploaded!",
            photoId: photoId
        )
        currentNotification = notification
        isShowing = true
        
        // Auto-hide after 3 seconds
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.hideNotification()
        }
    }
    
    func showErrorNotification(_ error: String, for photoId: String) {
        transformingPhotos.remove(photoId)
        
        let notification = GlobalNotification(
            type: .error,
            message: "Upload failed: \(error)",
            photoId: photoId
        )
        currentNotification = notification
        isShowing = true
        
        // Auto-hide after 4 seconds for errors
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            self.hideNotification()
        }
    }
    
    private func updateTransformingNotification() {
        let count = transformingPhotos.count
        
        if count > 0 {
            let message = count == 1 ? "Transforming image..." : "Transforming \(count) images..."
            let notification = GlobalNotification(
                type: .transforming,
                message: message,
                photoId: nil // Multiple photos, so no specific ID
            )
            currentNotification = notification
            isShowing = true
        } else {
            // No more transformations in progress
            hideNotification()
        }
    }
    
    func hideNotification() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentNotification = nil
        }
    }
    
    func clearTimer() {
        notificationTimer?.invalidate()
        notificationTimer = nil
    }
    
    // Manual cleanup method for edge cases
    func removeTransformingPhoto(_ photoId: String) {
        transformingPhotos.remove(photoId)
        updateTransformingNotification()
    }
    
    // Debug method to get current status
    var currentStatus: String {
        return "Transforming: \(transformingPhotos.count) photos"
    }
}
