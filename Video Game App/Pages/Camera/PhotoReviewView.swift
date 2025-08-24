import SwiftUI
import UIKit
import Supabase

struct PhotoReviewView: View {
    let capturedImage: UIImage
    @State private var selectedStyle: String = "Illustration"
    @EnvironmentObject var galleryViewModel: GalleryViewModel
    @EnvironmentObject var notificationManager: GlobalNotificationManager
    @Environment(\.dismiss) var dismiss
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isProcessing: Bool = false
    
    // Animated style options with pricing
    let environmentStyles = [
        ("Illustration", "$0.03", "🎮", "Painted, stylized", "illustration_bg"),
        ("Anime", "$0.03", "💫", "Hand-drawn", "anime_bg")
    ]
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    
                    // Photo Display
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .padding(.horizontal)
                    
                    // Style Selection Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Choose a Style")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("• 3 credits each")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Environment Styles Row
                        VStack(alignment: .leading, spacing: 8) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(environmentStyles, id: \.0) { style in
                                        StyleSelectionButton(
                                            title: style.0,
                                            icon: style.2,
                                            description: style.3,
                                            backgroundImage: style.4,
                                            isSelected: selectedStyle == style.0
                                        ) {
                                            selectedStyle = style.0
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title *")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter a title for your photo", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTitleFocused)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Description Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Add a description (optional)", text: $description, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isDescriptionFocused)
                            .lineLimit(3...6)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Accept Button
                    Button(action: handleAcceptPhoto) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            Text(isProcessing ? "Processing..." : "Accept Photo")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.accentColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    
                    // Cancel Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(isProcessing)
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .navigationTitle("Review Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isProcessing)
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                isTitleFocused = false
                isDescriptionFocused = false
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTitleFocused = false
                        isDescriptionFocused = false
                    }
                }
            }
    }
    
    // MARK: - Actions
    private func handleAcceptPhoto() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessing = true
        
        // Generate a unique ID for this photo upload
        let photoId = UUID().uuidString
        
        // Add loading placeholder to gallery
        galleryViewModel.addLoadingPhoto(photoId)
        
        // Show global transforming notification with style info
        notificationManager.showTransformingNotification(for: photoId)
        
        // Make pixels upright and portrait before sending
        let normalized = capturedImage.normalizedOrientation()
        let portrait = normalized.centerCropped(toAspect: 3.0/4.0)
        let finalImage = portrait.resized(maxLongSide: 1536)
        
        let runwareAPI = RunwareAPI()
        
        // Use style-based configuration
        runwareAPI.sendImageToRunware(image: finalImage, style: selectedStyle) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let runwareURLString):
                    guard let runwareURL = URL(string: runwareURLString) else {
                        Task { @MainActor in
                            galleryViewModel.removeLoadingPhoto(photoId)
                            notificationManager.showErrorNotification("Invalid response from API", for: photoId)
                            isProcessing = false
                        }
                        return
                    }
                    
                    // Save into Supabase
                    Task {
                        do {
                            let service = PhotoService(client: supabase)
                            _ = try await service.saveRunwareImage(
                                runwareURL: runwareURL,
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                description: description.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            
                            await galleryViewModel.refreshFromSupabase()
                            
                            await MainActor.run {
                                galleryViewModel.removeLoadingPhoto(photoId)
                                notificationManager.showSuccessNotification(for: photoId)
                                isProcessing = false
                                dismiss()
                            }
                        } catch {
                            await MainActor.run {
                                galleryViewModel.removeLoadingPhoto(photoId)
                                notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                                isProcessing = false
                            }
                        }
                    }
                    
                case .failure(let error):
                    Task { @MainActor in
                        galleryViewModel.removeLoadingPhoto(photoId)
                        notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                        isProcessing = false
                    }
                }
            }
        }
    }
}

// MARK: - StyleSelectionButton Component
struct StyleSelectionButton: View {
    let title: String
    let icon: String
    let description: String
    let backgroundImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Background image - no extra container
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 130)
                    .clipped()

                // Gradient overlay for better readability
                LinearGradient(
                    colors: [.black.opacity(0.55), .black.opacity(0.25), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // Clean content layout
                VStack(alignment: .leading, spacing: 6) {
                    
                    // Checkmark in top left
                    if isSelected {
                        HStack {
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.accentColor)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Text(icon)
                            .font(.title2)
                            .shadow(color: .black.opacity(0.8), radius: 3)
                        
                        Spacer()
                    }
                        
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: isSelected
                                    ? [.accentColor, .accentColor.opacity(0.7)]
                                    : [.gray, .gray.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .clipShape(Capsule())
                        )
                        .shadow(color: .gray.opacity(0.5), radius: 2)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.95))
                        .shadow(radius: 2)
                        .lineLimit(2)
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(6)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .shadow(color: isSelected ? .accentColor.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 8 : 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .padding(.vertical, 2)
        .buttonStyle(PlainButtonStyle())
    }
}
