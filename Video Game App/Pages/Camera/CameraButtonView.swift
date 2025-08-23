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
        ("Illustration", "$0.03", "🎮", "Painted, stylized"),
        ("Anime", "$0.03", "💫", "Bright, hand-drawn"),
        ("Pixel Art", "$0.03", "👾", "Retro, pixelated")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {

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

                    // Animated Style Selection Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Choose a Style")
                                .font(.headline)
                                .fontWeight(.semibold)
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
                                            price: style.1,
                                            icon: style.2,
                                            description: style.3,
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

// MARK: - Style Selection Button
struct StyleSelectionButton: View {
    let title: String
    let price: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(icon)
                        .font(.title2)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)

                    Text(price)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .accentColor)
                }
            }
            .padding(12)
            .frame(width: 140, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(UIColor.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
