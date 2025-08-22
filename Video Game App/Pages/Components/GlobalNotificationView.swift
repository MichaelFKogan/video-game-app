import SwiftUI

struct GlobalNotificationView: View {
    @ObservedObject var notificationManager: GlobalNotificationManager
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    
    var body: some View {
        ZStack {
            if notificationManager.isShowing, let notification = notificationManager.currentNotification {
                VStack {
                    HStack {
                        Spacer()
                        
                        // Notification card
                        HStack(spacing: 12) {
                            // Icon
                            Image(systemName: iconForType(notification.type))
                                .foregroundColor(colorForType(notification.type))
                                .font(.system(size: 16, weight: .medium))
                            
                            // Message
                            Text(notification.message)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            // Progress indicator for transforming
                            if notification.type == .transforming {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: colorForType(notification.type)))
                                    .scaleEffect(0.8)
                            }
                            
                            // Show count badge for multiple transformations
                            if notification.type == .transforming && notification.message.contains("images") {
                                Text("\(notificationManager.transformingPhotosCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(colorForType(notification.type))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorForType(notification.type).opacity(0.3), lineWidth: 1)
                        )
                        .padding(.trailing, 16)
//                        .padding(.top, 60) // Account for safe area
                    }
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: notificationManager.isShowing)
            }
        }
        .zIndex(1000) // Ensure it appears above everything
    }
    
    private func iconForType(_ type: NotificationType) -> String {
        switch type {
        case .transforming:
            return "wand.and.stars"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func colorForType(_ type: NotificationType) -> Color {
        switch type {
        case .transforming:
            return accentColorName.toColor()
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        VStack {
            Text("App Content")
                .font(.title)
            Spacer()
        }
        
        GlobalNotificationView(notificationManager: {
            let manager = GlobalNotificationManager()
            manager.showTransformingNotification(for: "preview-photo-id")
            return manager
        }())
    }
}
