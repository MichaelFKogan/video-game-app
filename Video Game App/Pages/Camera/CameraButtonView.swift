import SwiftUI
import AVFoundation
import UIKit

// MARK: - CameraButtonView
struct CameraButtonView: View {
    @StateObject private var cameraService = CameraService()
    @State private var selectedUIImage: UIImage?
    @State private var showLibraryPicker = false
    @EnvironmentObject var galleryViewModel: GalleryViewModel
    @EnvironmentObject var notificationManager: GlobalNotificationManager

    // 1️⃣ Add a state variable for selected tags
    @State private var selectedTag: String? = nil

    // 2️⃣ Add state variable for selected animated style
    @State private var selectedStyle: String = "Illustration"

    // 3️⃣ Add custom positive prompt for testing
    @State private var customPositivePrompt: String = ""

    // 2️⃣ Your tags array
    let tags = ["📓 Daily Journal", "⚔️ Quests", "🥪 Rations", "🗺️ Map", "📦 Inventory"]

    // 3️⃣ Animated style options with pricing
    // Scenes/objects (cheaper)
    let environmentStyles = [
        ("Illustration", "$0.03", "🎮", "Painted, stylized", "illustration_bg"),
        ("Anime", "$0.03", "💫", "Hand-drawn", "anime_bg")
//        ("Pixel Art", "$0.03", "👾", "Retro, pixelated", "pixelart_bg")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {

                    // Live Camera
                    ZStack {
                        if cameraService.capturedImage == nil {
                            CameraPreview(session: cameraService.session, position: cameraService.cameraPosition)
                                .cornerRadius(12)
                                .shadow(radius: 6)

                        } else {
                            Image(uiImage: cameraService.capturedImage!)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .shadow(radius: 6)
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .padding(.horizontal)

                    Spacer()

                // Style indicator overlay
                    VStack {
                        HStack {
                            Text("Style:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedStyle)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .background(Color(UIColor.systemBackground).opacity(0.9))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }

                    // Buttons: Camera - Photo Library - Clear
                    HStack(spacing: 10) {

                        // Photo library button
                        Button {
                            showLibraryPicker = true
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                                .padding(12)
                                .background(Color(UIColor.systemGray6)).opacity(cameraService.capturedImage == nil ? 1 : 0)
                                .foregroundColor(.primary).opacity(cameraService.capturedImage == nil ? 1 : 0)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Choose from photo library")

                        if cameraService.capturedImage == nil {

                            // Camera capture button
                            Button {
                                cameraService.capturePhoto()
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .padding(24)
                                    .background(Color.accentColor)
                                    .foregroundColor(.primary)
                                    .clipShape(Circle())
                            }

                            // Reverse / switch camera button (top-right)
                            Button {
                                cameraService.switchCamera()
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath.camera")
                                    .font(.system(size: 18, weight: .semibold))
                                    .padding(12)
                                    .background(Color(UIColor.systemGray6))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .accessibilityLabel("Switch camera")
                            .allowsHitTesting(true)

                        } else {
                            // ACCEPT PHOTO BUTTON (refactored to explicit initializer)
                            Button(action: handleAcceptPhoto) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                                    .padding(22)
                                    .background(cameraService.capturedImage == nil ? Color.gray : Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Accept photo")
                            .disabled(cameraService.capturedImage == nil)

                            // CLEAR / RETAKE BUTTON
                            Button(action: { cameraService.capturedImage = nil }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16))
                                    .fontWeight(.bold)
                                    .padding(12)
                                    .background(Color(UIColor.systemGray6).opacity(cameraService.capturedImage == nil ? 0 : 1))
                                    .foregroundColor(.red.opacity(cameraService.capturedImage == nil ? 0 : 1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()
                        .padding(.vertical, 12)

                    // Animated Style Selection Section
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

                        // Environment Styles Row (Cheaper)
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
                        .padding(.bottom, 120)
                    }
                }
            }
            .onAppear {
                cameraService.startSession()
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .sheet(isPresented: $showLibraryPicker) {
                PhotoLibraryPickerView(isPresented: $showLibraryPicker, selectedImage: $cameraService.capturedImage)
            }
        }
    }

    // MARK: - Actions
    private func handleAcceptPhoto() {
        guard let raw = cameraService.capturedImage else { return }

        // Generate a unique ID for this photo upload
        let photoId = UUID().uuidString

        // Add loading placeholder to gallery
        galleryViewModel.addLoadingPhoto(photoId)

        // Show global transforming notification with style info
        notificationManager.showTransformingNotification(for: photoId)

        // Use custom prompt if provided, otherwise use selected style
        let styleToUse = customPositivePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? selectedStyle
            : "Custom" // We'll handle custom prompts differently

        // Make pixels upright and portrait before sending
        let normalized = raw.normalizedOrientation()
        let portrait = normalized.centerCropped(toAspect: 3.0/4.0) // choose 9/16, 2/3, etc.
        let finalImage = portrait.resized(maxLongSide: 1536)        // optional but tidy

        // Reset camera to live preview immediately for better UX
        cameraService.capturedImage = nil

        let runwareAPI = RunwareAPI()

        // Handle custom prompt vs style-based processing
        if !customPositivePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Use custom prompt with default configuration
            let customConfig = ModelConfiguration(
                model: "bytedance:4@1",
                positivePrompt: customPositivePrompt,
                cfgScale: 1.0
            )
            runwareAPI.sendImageToRunwareWithConfig(image: finalImage, config: customConfig) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let runwareURLString):
                        guard let runwareURL = URL(string: runwareURLString) else {
                            Task { @MainActor in
                                galleryViewModel.removeLoadingPhoto(photoId)
                                notificationManager.showErrorNotification("Invalid response from API", for: photoId)
                            }
                            return
                        }

                        // Save into Supabase
                        Task {
                            do {
                                let service = PhotoService(client: supabase)
                                _ = try await service.saveRunwareImage(
                                    runwareURL: runwareURL,
                                    description: selectedTag ?? "Untitled"
                                )

                                await galleryViewModel.refreshFromSupabase()

                                await MainActor.run {
                                    galleryViewModel.removeLoadingPhoto(photoId)
                                    notificationManager.showSuccessNotification(for: photoId)
                                }
                            } catch {
                                await MainActor.run {
                                    galleryViewModel.removeLoadingPhoto(photoId)
                                    notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                                }
                            }
                        }

                    case .failure(let error):
                        Task { @MainActor in
                            galleryViewModel.removeLoadingPhoto(photoId)
                            notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                        }
                    }
                }
            }
        } else {
            // Use style-based configuration
            RunwareAPI().sendImageToRunware(image: finalImage, style: styleToUse) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let runwareURLString):
                        guard let runwareURL = URL(string: runwareURLString) else {
                            Task { @MainActor in
                                galleryViewModel.removeLoadingPhoto(photoId)
                                notificationManager.showErrorNotification("Invalid response from API", for: photoId)
                            }
                            return
                        }

                        // Save into Supabase
                        Task {
                            do {
                                let service = PhotoService(client: supabase)
                                _ = try await service.saveRunwareImage(
                                    runwareURL: runwareURL,
                                    description: selectedTag ?? "Untitled"
                                )

                                await galleryViewModel.refreshFromSupabase()

                                await MainActor.run {
                                    galleryViewModel.removeLoadingPhoto(photoId)
                                    notificationManager.showSuccessNotification(for: photoId)
                                }
                            } catch {
                                await MainActor.run {
                                    galleryViewModel.removeLoadingPhoto(photoId)
                                    notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                                }
                            }
                        }

                    case .failure(let error):
                        Task { @MainActor in
                            galleryViewModel.removeLoadingPhoto(photoId)
                            notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                        }
                    }
                }
            }
        }
    }
}

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
//            .scaleEffect(isSelected ? 1.06 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .padding(.vertical, 2)
        .buttonStyle(PlainButtonStyle())
    }
}
