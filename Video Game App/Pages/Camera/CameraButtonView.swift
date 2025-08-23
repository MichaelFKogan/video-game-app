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
        ("Anime", "$0.03", "💫", "Bright, hand-drawn")
    ]
    
//    // Faces/people (premium)
//    let faceStyles = [
//        ("Illustration Portrait", "$0.15", "🎮👤", "Artistic, detailed"),
//        ("Anime Portrait", "$0.15", "💫👤", "Expressive, animated")
//    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    
//                    // Page Title
//                    HStack {
//                        Text("Camera")
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                        Spacer()
//                    }
//                    .padding()

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
//                                .background(Color(UIColor.systemGray6))
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

                        
                    }else{
                            
//                            let isUsingCustomPrompt = !customPositivePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//
//                            // Selected Style Display
//                            VStack(spacing: 4) {
//                              Text(isUsingCustomPrompt ? "Prompt:" : "Style:")
//                                .font(.caption).foregroundColor(.secondary)
//                              Text(isUsingCustomPrompt ? "Custom" : selectedStyle)
//                                .font(.caption).fontWeight(.semibold)
//                            }
//                            .padding(.horizontal, 8)
//                            .padding(.vertical, 4)
//                            .background(Color(UIColor.systemGray6))
//                            .cornerRadius(8)
                            
            // ACCEPT PHOTO BUTTON
                // SEND TO API
                    Button {
                        guard let raw = cameraService.capturedImage else { return }
                        
                        // Generate a unique ID for this photo upload
                        let photoId = UUID().uuidString
                        
                        // Add loading placeholder to gallery
                        galleryViewModel.addLoadingPhoto(photoId)
                        
                        // Show global transforming notification with style info
                        notificationManager.showTransformingNotification(for: photoId)
                        
                        // Use custom prompt if provided, otherwise use selected style
                        let promptToUse = customPositivePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? selectedStyle
                            : customPositivePrompt
                        print("🎨 Processing image with prompt: \(promptToUse)")

                        // Make pixels upright and portrait before sending
                        let normalized = raw.normalizedOrientation()
                        let portrait = normalized.centerCropped(toAspect: 3.0/4.0) // choose 9/16, 2/3, etc.
                        let finalImage = portrait.resized(maxLongSide: 1536)        // optional but tidy
                        
                        // Reset camera to live preview immediately for better UX
                        cameraService.capturedImage = nil
                        
                        let runwareAPI = RunwareAPI()
                        
                        
                        
                        
                            RunwareAPI().sendImageToRunware(image: finalImage, style: promptToUse) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let runwareURLString):
                                    print("✅ Got transformed image: \(runwareURLString)")
                                    
                                    guard let runwareURL = URL(string: runwareURLString) else {
                                        print("❌ Invalid URL string from Runware")
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
                                            let publicURL = try await service.saveRunwareImage(
                                                runwareURL: runwareURL,
                                                description: selectedTag ?? "Untitled"
                                            )
                                            print("✅ Uploaded & saved. Public URL: \(publicURL)")
                                            
                                            // Update GalleryViewModel immediately
                                            await galleryViewModel.refreshFromSupabase()
                                            
                                            // Remove loading placeholder and show success
                                            await MainActor.run {
                                                galleryViewModel.removeLoadingPhoto(photoId)
                                                notificationManager.showSuccessNotification(for: photoId)
                                            }
                                        } catch {
                                            print("❌ Supabase upload failed: \(error)")
                                            await MainActor.run {
                                                galleryViewModel.removeLoadingPhoto(photoId)
                                                notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                                            }
                                        }
                                    }
                                    
                                    case .failure(let error):
                                        print("❌ Runware error: \(error.localizedDescription)")
                                        Task { @MainActor in
                                            galleryViewModel.removeLoadingPhoto(photoId)
                                            notificationManager.showErrorNotification(error.localizedDescription, for: photoId)
                                        }
                                    }
                                }
                            }
                        } label: {
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
                            
                        Button {
                            cameraService.capturedImage = nil
                        } label: {
                            // Photo library button
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
//                .padding(.bottom, 40)
                
//                Divider()
                
//                // Custom Positive Prompt Section (for testing)
//                VStack(alignment: .leading, spacing: 12) {
//                    HStack {
//                        Text("🧪 Custom Prompt (Testing)")
//                            .font(.headline)
//                            .fontWeight(.semibold)
//                        Spacer()
//                        Text("Overrides style selection")
//                            .font(.caption)
//                            .foregroundColor(.orange)
//                            .fontWeight(.medium)
//                    }
//                    .padding(.horizontal)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Enter custom positive prompt:")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .padding(.horizontal)
//                        
//                        TextField("e.g., 'cinematic lighting, dramatic shadows, oil painting style'", text: $customPositivePrompt, axis: .vertical)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .lineLimit(2...4)
//                            .padding(.horizontal)
//                    }
//                }
//                .padding(.vertical, 8)
                
                Divider()
                
                // Animated Style Selection Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Choose a Style")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
//                        Text("Selected: \(selectedStyle)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Environment Styles Row (Cheaper)
                    VStack(alignment: .leading, spacing: 8) {
                        
//                        HStack {
//                            Text("🖼️ Scenes & Objects")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                            Text("• $0.03 per image")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                                .fontWeight(.semibold)
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                        
//                        HStack {
//                            Text("Best for landscapes, buildings, and objects. Not optimized for faces.")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                        
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
                    
//                    // Face Styles Row (More Expensive)
//                    VStack(alignment: .leading, spacing: 8) {
//                        HStack {
//                            Text("👤 Faces and People")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                            Text("• $0.15 per image")
//                                .font(.caption)
//                                .foregroundColor(.orange)
//                                .fontWeight(.semibold)
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                        
//                        HStack {
//                            Text("Best for photos with people. Faces look more natural.")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                        
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 12) {
//                                ForEach(faceStyles, id: \.0) { style in
//                                    StyleSelectionButton(
//                                        title: style.0,
//                                        price: style.1,
//                                        icon: style.2,
//                                        description: style.3,
//                                        isSelected: selectedStyle == style.0
//                                    ) {
//                                        selectedStyle = style.0
//                                    }
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
                    
                    
                    
//                }
//                .padding(.vertical, 8)
                
//                Divider()
                
                
                
                
                
                // Quest Buttons
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(tags, id: \.self) { tag in
//                            Button(action: {
//                                // Toggle selection
//                                if selectedTag == tag {
//                                    selectedTag = nil
//                                } else {
//                                    selectedTag = tag
//                                }
//                            }) {
//                                Text(tag)
//                                    .font(.subheadline)
//                                    .fontWeight(.bold)
//                                    .padding(.vertical, 16)
//                                    .padding(.horizontal, 14)
//                                    .background(
//                                        selectedTag == tag ? Color.accentColor : Color(UIColor.systemGray6)
//                                    )
//                                    .foregroundColor(selectedTag == tag ? .white : .primary)
//                                    .clipShape(Rectangle())
//                                    .cornerRadius(4)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical, 8)
                
                }
                
                
                

//                Spacer()
                }
//                .padding(.bottom, 120) // Add some bottom padding for better scrolling
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
