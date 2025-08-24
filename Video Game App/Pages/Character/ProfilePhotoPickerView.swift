//
//  ProfilePhotoPickerView.swift
//  Video Game App
//
//  Created by Mike K on 8/18/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct ProfilePhotoPickerView: View {
    @StateObject private var cameraService = CameraService()
    @State private var showLibraryPicker = false
    @State private var selectedStyle = "Illustration"
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showProcessingView = false
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    
    let onPhotoSelected: (String) -> Void
    
    // Style options matching PhotoReviewView
    let environmentStyles = [
        ("Illustration", "$0.03", "🎮", "Painted, stylized", "illustration_bg"),
        ("Anime", "$0.03", "💫", "Hand-drawn", "anime_bg")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showProcessingView {
                    // Processing View
                    processingView
                } else {
                    // Main Camera View
                    mainCameraView
                }
            }
            .navigationTitle("Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Main Camera View
    private var mainCameraView: some View {
        VStack(spacing: 0) {
            // Live Camera - matching CameraButtonView exactly
            CameraPreview(session: cameraService.session, position: cameraService.cameraPosition)
                .cornerRadius(12)
                .shadow(radius: 6)
                .frame(height: UIScreen.main.bounds.height * 0.55)
                .padding(.horizontal)
                .padding(.top, 60)
            
            Spacer()
            
            // Style Selection (only show when photo is captured)
            if cameraService.capturedImage != nil {
                styleSelectionView
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            
            // Buttons: Camera - Photo Library - Switch Camera
            HStack(spacing: 10) {
                // Photo library button
                Button {
                    showLibraryPicker = true
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18))
                        .padding(12)
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Choose from photo library")
                
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
                
                // Reverse / switch camera button
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
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            
            Divider()
                .padding(.bottom, 6)
        }
        .onChange(of: cameraService.capturedImage) { newImage in
            if newImage != nil {
                // Show style selection and processing options
            }
        }
    }
    
    // MARK: - Style Selection View
    private var styleSelectionView: some View {
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
                }
            }
            
            // Process Button
            Button(action: {
                Task {
                    await processProfilePhoto()
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text(isProcessing ? "Processing..." : "Set as Profile Photo")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isProcessing ? Color.gray : Color.accentColor)
                .cornerRadius(12)
            }
            .disabled(isProcessing)
            
            // Cancel Button
            Button(action: {
                cameraService.capturedImage = nil
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
            }
            .disabled(isProcessing)
        }
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Processing animation
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                
                Text("Transforming your photo...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This may take a few moments")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Photo Processing
    private func processProfilePhoto() async {
        guard let image = cameraService.capturedImage else { return }
        
        await MainActor.run {
            isProcessing = true
            showProcessingView = true
        }
        
        // Apply the same image processing as PhotoReviewView
        let normalized = image.normalizedOrientation()
        let portrait = normalized.centerCropped(toAspect: 3.0/4.0)
        let finalImage = portrait.resized(maxLongSide: 1536)
        
        let runwareAPI = RunwareAPI()
        
        runwareAPI.sendImageToRunware(image: finalImage, style: selectedStyle) { result in
            Task { @MainActor in
                isProcessing = false
                showProcessingView = false
                
                switch result {
                case .success(let imageURL):
                    // Save to Supabase profile
                    await saveProfilePhotoToDatabase(imageURL: imageURL)
                    onPhotoSelected(imageURL)
                    dismiss()
                    
                case .failure(let error):
                    errorMessage = "Failed to process photo: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func saveProfilePhotoToDatabase(imageURL: String) async {
        guard let userID = session.user?.id else {
            print("No user ID found")
            return
        }
        
        do {
            let response = try await supabase.database
                .from("profiles")
                .update(["avatar_url": imageURL], returning: .representation)
                .eq("id", value: userID)
                .execute()
            
            print("Profile photo updated successfully!")
            print("Updated row:", response.data ?? "nil")
            
        } catch {
            print("Error updating profile photo: \(error.localizedDescription)")
            errorMessage = "Failed to save profile photo: \(error.localizedDescription)"
            showError = true
        }
    }
}



//// MARK: - StyleSelectionButton Component (copied from PhotoReviewView)
//struct StyleSelectionButton: View {
//    let title: String
//    let icon: String
//    let description: String
//    let backgroundImage: String
//    let isSelected: Bool
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            ZStack(alignment: .bottomLeading) {
//                // Background image - no extra container
//                Image(backgroundImage)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 140, height: 130)
//                    .clipped()
//
//                // Gradient overlay for better readability
//                LinearGradient(
//                    colors: [.black.opacity(0.55), .black.opacity(0.25), .clear],
//                    startPoint: .bottom,
//                    endPoint: .top
//                )
//
//                // Clean content layout
//                VStack(alignment: .leading, spacing: 6) {
//                    
//                    // Checkmark in top left
//                    if isSelected {
//                        HStack {
//                            ZStack {
//                                Image(systemName: "circle.fill")
//                                    .font(.system(size: 28))
//                                    .foregroundColor(.accentColor)
//                                Image(systemName: "checkmark")
//                                    .font(.system(size: 14, weight: .bold))
//                                    .foregroundColor(.white)
//                            }
//                            Spacer()
//                        }
//                    }
//                    
//                    HStack {
//                        Text(icon)
//                            .font(.title2)
//                            .shadow(color: .black.opacity(0.8), radius: 3)
//                        
//                        Spacer()
//                    }
//                        
//                    Text(title)
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 3)
//                        .background(
//                            LinearGradient(
//                                colors: isSelected
//                                    ? [.accentColor, .accentColor.opacity(0.7)]
//                                    : [.gray, .gray.opacity(0.7)],
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                            .clipShape(Capsule())
//                        )
//                        .shadow(color: .gray.opacity(0.5), radius: 2)
//
//                    Text(description)
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.95))
//                        .shadow(radius: 2)
//                        .lineLimit(2)
//                }
//                .padding(8)
//            }
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            .padding(6)
//            .overlay(
//                RoundedRectangle(cornerRadius: 18)
//                    .stroke(
//                        isSelected ? Color.accentColor : Color.gray.opacity(0.3),
//                        lineWidth: isSelected ? 3 : 1
//                    )
//            )
//            .shadow(color: isSelected ? .accentColor.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 8 : 4, x: 0, y: 2)
//            .animation(.easeInOut(duration: 0.2), value: isSelected)
//        }
//        .padding(.vertical, 2)
//        .buttonStyle(PlainButtonStyle())
//    }
//}
